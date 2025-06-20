import sys

from lark import Lark, Transformer, Token, Visitor

from kyupy import readtext


class ModuleDeclaration:
    def __init__(self, name):
        self.name = name
        self.port_list = []
        self.port_dict = {}

    def __repr__(self):
        return f"{self.name}({self.port_list})"


class Port:
    def __init__(self, name=None):
        self.name = name
        self.direction = "inout"
        self.data_type = "logic"
        self.net_type = "wire"
        self.ranges = []

    def __repr__(self):
        return f"{self.direction} {self.net_type} {self.data_type} {self.ranges} {self.name}"

    def load_from_tree(self, tree):
        first_range = True
        for child in tree.children:
            if isinstance(child, Token):
                if child.type == 'PORT_DIRECTION':
                    self.direction = child.value
            else:
                if child.data == 'packed_dimension':
                    if first_range:
                        self.ranges = []
                        first_range = False
                    tree2 = child.children[0]
                    left = int(tree2.children[0].value)
                    right = int(tree2.children[1].value)
                    self.ranges.append((left, right))
        return self

    def width(self):
        if len(self.ranges) == 0: return 1
        w = 0
        for r in self.ranges:
            w += r[0] - r[1] + 1
        return w


class T1(Transformer):
    @staticmethod
    def name(args):
        s = args[0].value
        return s[1:-1] if s[0] == '\\' else s


class ExtractModulesAndPorts(Visitor):
    def __init__(self):
        super().__init__()
        self.modules = []

    def module_declaration(self, tree):
        name = tree.children[0].children[0]
        self.modules.append(ModuleDeclaration(name))

    def ansi_port_declaration(self, tree):
        name = next(tree.find_data('port_identifier')).children[0]
        port = Port(name)
        if len(self.modules[-1].port_list) > 0:
            prev_port = self.modules[-1].port_list[-1]
            port.direction = prev_port.direction
            port.net_type = prev_port.net_type
            port.data_type = prev_port.data_type
            port.ranges = list(prev_port.ranges)
        if tree.children[0].data == 'net_port_header':
            port.load_from_tree(tree.children[0])
        self.modules[-1].port_list.append(port)
        self.modules[-1].port_dict[port.name] = port

    def list_of_ports(self, tree):
        for port_identifier in tree.find_data('port_identifier'):
            port = Port(port_identifier.children[0])
            self.modules[-1].port_list.append(port)
            self.modules[-1].port_dict[port.name] = port

    def port_declaration(self, tree):
        port_prototype = Port().load_from_tree(tree)
        for pid in next(tree.find_data('list_of_port_identifiers')).children:
            name = pid.children[0]
            port = self.modules[-1].port_dict[name]
            port.direction = port_prototype.direction
            port.net_type = port_prototype.net_type
            port.data_type = port_prototype.data_type
            port.ranges = list(port_prototype.ranges)


GRAMMAR = r"""
    start: (skip2next_module? module_declaration)*
    skip2next_module: /(?!\s+input).+?(?=\smodule)/s
    module_declaration: ( module_nonansi_header module_item* | module_ansi_header module_item* ) skip2next_endmodule? "endmodule"
    skip2next_endmodule: /.+?(?=\sendmodule)/s
    module_nonansi_header: "module" name list_of_ports ";"
    list_of_ports: "(" port_identifier ( "," port_identifier )* ")"
    module_ansi_header: "module" name list_of_port_declarations? ";"
    list_of_port_declarations: "(" ansi_port_declaration ( "," ansi_port_declaration )* ")"
    ansi_port_declaration: net_port_header? port_identifier
    net_port_header: PORT_DIRECTION? _net_port_type
    PORT_DIRECTION: "input" | "output" | "inout" | "ref"
    _net_port_type: NET_TYPE? _data_type_or_implicit
    _data_type_or_implicit: _data_type | _implicit_data_type
    _implicit_data_type: SIGNING? packed_dimension*
    _data_type: INTEGER_VECTOR_TYPE SIGNING? packed_dimension*
    NET_TYPE: "wire"
    INTEGER_VECTOR_TYPE: "bit" | "logic" | "reg"
    packed_dimension: "[" constant_range "]"
    constant_range: /[0-9]+/ ":" /[0-9]+/
    port_identifier: name
    module_item.1: port_declaration
    port_declaration: PORT_DIRECTION _net_port_type list_of_port_identifiers
    list_of_port_identifiers: port_identifier ( "," port_identifier )* ";"
    SIGNING: ( "signed" | "unsigned" )
    name: ( /[a-z_][a-z0-9_]*/i | /\\[^\t \r\n]+[\t \r\n]/i | /[0-9]+'[bdh][0-9a-f]+/i )
    %import common.NEWLINE
    COMMENT: /\/\*(\*(?!\/)|[^*])*\*\// | /\(\*(\*(?!\))|[^*])*\*\)/ |  "//" /(.)*/ NEWLINE
    %ignore ( /\r?\n/ | COMMENT )+
    %ignore /[\t \f]+/
    """


def parse(text):
    tree = Lark(GRAMMAR).parse(text)
    tree = T1().transform(tree)
    visitor = ExtractModulesAndPorts()
    visitor.visit_topdown(tree)
    return visitor.modules


def load(file):
    return parse(readtext(file))


def gen_wrapper(module):
    v = f"module {module.name}_wrapped(" + ", ".join([port.name for port in module.port_list]) + ", TCK, TMS, TRSTn, TDI, TDO);\n"
    num_inputs = 0
    num_outputs = 0
    for port in module.port_list:
        r = f"[{port.ranges[0][0]}:{port.ranges[0][1]}] " if port.ranges else ""
        v += f"{port.direction} {r}{port.name};\n"
        if port.direction == "input":
            num_inputs += port.width()
        else:
            num_outputs += port.width()
    v += "input TCK, TMS, TRSTn, TDI;\noutput TDO;\n"
    inputs = ", ".join([port.name for port in module.port_list if port.direction == "input"])
    v += f"wire [{num_inputs-1}:0] inputs = {{{inputs}}};\n"
    v += f"wire [{num_outputs-1}:0] outputs;\n"
    v += f"wire [{num_inputs-1}:0] to_core;\n"
    v += f"wire [{num_outputs-1}:0] from_core;\n"
    out_idx = num_outputs-1
    for port in module.port_list:
        if port.direction == "input": continue
        v += f"assign {port.name} = outputs[{out_idx}:{out_idx-port.width()+1}];\n"
    out_idx = num_outputs-1
    in_idx = num_inputs-1
    connections = []
    for port in module.port_list:
        if port.direction == "input":
            connections.append(f"to_core[{in_idx}:{in_idx-port.width()+1}]")
            in_idx -= port.width()
        else:
            connections.append(f"from_core[{out_idx}:{out_idx-port.width()+1}]")
            out_idx -= port.width()
    v += f"{module.name} core({', '.join(connections)});\n"
    v += f"jtag_tap #({num_inputs}, {num_outputs}) tap (TCK, TMS, TRSTn, TDI, TDO, inputs, to_core, outputs, from_core);\n"
    v += "endmodule\n"
    return v


if __name__ == '__main__':
    modules = load(sys.argv[1])
    for module in modules:
        with open(f'{module.name}_wrapped.v', 'w') as f:
            f.write(gen_wrapper(module))
    #print(modules)
    #modules = load('tests/nonansi.v')
    #print(modules)

