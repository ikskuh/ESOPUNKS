const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const global_allocator = &gpa.allocator;

pub fn main() anyerror!void {
    var exa = EXA{
        .memory = std.heap.ArenaAllocator.init(global_allocator),
        .code = undefined,
    };
}

pub const EXA = struct {
    const Self = @This();

    const Error = error{
        DivideByZero,
        MathWithKeyword,
        InvalidFRegisterAccess,
        InvalidHardwareRegisterAccess,
        InvalidFileAccess,
        InvalidLinkTraversal,

        // Non-fatal error that will just let the
        RegisterAccessBlocking,
    };

    memory: std.heap.ArenaAllocator,

    mode: CommunicationMode = .global,

    x: Value = 0,
    t: Value = 0,

    code: []Instruction,
    ip: usize = 0,

    pub fn step(self: *Self) Error!void {
        self.stepInteral() catch |err| switch (err) {
            error.RegisterAccessBlocking => {},
            else => |e| return e,
        };
    }

    fn stepInteral(self: *Self) !void {
        switch (self.code[self.ip]) {
            .COPY => |instr| {
                try self.writeRegister(instr[0], try instr[1].get(self));
            },

            else => @panic("TODO: Instruction not implemented yet!"),
        }
    }

    fn readRegister(self: *Self, reg: Register) !Value {
        return switch (reg) {
            .X => self.x,
            .T => self.t,
            .F => {
                @panic("TODO: Implement F reading!");
            },
            .M => {
                @panic("TODO: Implement M reading!");
            },
        };
    }

    fn writeRegister(self: *Self, reg: Register, value: Value) !void {
        switch (reg) {
            .X => self.x = value,
            .T => self.t = value,
            .F => {
                @panic("TODO: Implement F writing!");
            },
            .F => {
                @panic("TODO: Implement M writing!");
            },
        }
    }
};

pub const CommunicationMode = enum { local, global };

pub const Number = i32;

pub const Keyword = *[]const u8;

pub const Value = union(enum) {
    const Self = @This();

    keyword: Keyword,
    number: Number,

    fn eql(lhs: Self, rhs: Self) bool {
        const Tag = @TagType(Self);
        if (@as(Tag, lhs) != @as(Tag, rhs))
            return false;
        return switch (lhs) {
            .number => |n| rhs.number == n,
            .keyword => |k| rhs.keyword == k,
        };
    }

    fn toNumber(self: Self) !Number {
        switch (self) {
            .number => |n| return n,
            else => return error.MathWithKeyword,
        }
    }
};

pub const Register = enum {
    X,
    T,
    F,
    M,
};

pub const Comparison = enum {
    @"=",
    @"<",
    @">",
};

pub const Label = struct {
    name: []const u8,
};

pub const RegisterOrNumber = union(enum) {
    register: Register,
    number: Number,

    fn get(self: @This(), exa: *EXA) !Number {
        return switch (self) {
            .number => |n| n,
            .register => |reg| blk: {
                const value = try exa.readRegister(reg);
                return try value.toNumber();
            },
        };
    }
};

pub const Instruction = union(enum) {
    // Manipulating Values
    COPY: Operands("R/N R"),
    ADDI: Operands("R/N R/N R"),
    SWIZ: Operands("R/N R/N R"),

    // Branching
    MARK: Operands("L"),
    JUMP: Operands("L"),
    TJMP: Operands("L"),
    FJMP: Operands("L"),

    // Testing values
    TEST: Operands("R/N EQ R/N"),

    // Lifecycle
    REPL: Operands("L"),
    HALT: Operands(""),
    KILL: Operands(""),

    // Movement
    LINK: Operands("R/N"),
    HOST: Operands("R"),

    // Communication
    MODE: Operands(""),
    @"VOID M": Operands(""),
    @"TEST MRD": Operands(""),

    // File Manipulation
    MAKE: Operands(""),
    GRAB: Operands("R/N"),
    FILE: Operands("R"),
    SEEK: Operands("R/N"),
    @"VOID F": Operands(""),
    DROP: Operands(""),
    WIPE: Operands(""),
    @"TEST EOF": Operands(""),

    // Miscellaneous
    NOTE: Operands("*"),
    NOOP: Operands(""),
    RAND: Operands("R/N R/N R"),

    fn Operands(comptime spec: []const u8) type {
        if (std.mem.eql(u8, spec, ""))
            return std.meta.Tuple(&[_]type{});

        const length = blk: {
            var iter = std.mem.split(spec, " ");
            var i = 0;
            while (iter.next()) |_| {
                i += 1;
            }
            break :blk i;
        };

        var types: [length]type = undefined;
        {
            var iter = std.mem.split(spec, " ");
            var i = 0;
            while (iter.next()) |item| : (i += 1) {
                types[i] = if (std.mem.eql(u8, item, "R/N"))
                    RegisterOrNumber
                else if (std.mem.eql(u8, item, "R"))
                    Register
                else if (std.mem.eql(u8, item, "L"))
                    Label
                else if (std.mem.eql(u8, item, "EQ"))
                    Comparison
                else if (std.mem.eql(u8, item, "*"))
                    []const u8
                else
                    @compileError("Invalid operand specification: " ++ item);
            }
        }
        return std.meta.Tuple(&types);
    }
};

pub const InstructionName = @TagType(Instruction);
