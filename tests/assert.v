`define assert(name, value, expect, description) \
        if (value !== expect) begin \
            $display("ASSERTION FAILED: '%s' (actual) %d != (expected) %d. %s", name, value, expect, description); \
            $finish; \
        end
