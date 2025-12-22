const std = @import("std");

var A: f32 = 0;
var B: f32 = 0;
var C: f32 = 0;

const cubeWidth: f32 = 20;
const width: u16 = 160;
const height: u16 = 44;
var zBuffer: [160 * 44]f32 = undefined;
var buffer: [160 * 44]u8 = undefined;
const backgroundASCIICode: u8 = ' ';
const distanceFromCam: i32 = 100;
const K1: f32 = 40;
const incrementSpeed: f32 = 0.6;

var x: f32 = 0;
var y: f32 = 0;
var z: f32 = 0;
var ooz: f32 = 0;
var xp: i32 = 0;
var yp: i32 = 0;
var idx: i32 = 0;

fn calculateX(i: f32, j: f32, k: f32) f32 {
    return j * @sin(A) * @sin(B) * @cos(C) - k * @cos(A) * @sin(B) * @cos(C) +
        j * @cos(A) * @sin(C) + k * @sin(A) * @sin(C) + i * @cos(B) * @cos(C);
}

fn calculateY(i: f32, j: f32, k: f32) f32 {
    return j * @cos(A) * @cos(C) + k * @sin(A) * @cos(C) -
        j * @sin(A) * @sin(B) * @sin(C) + k * @cos(A) * @sin(B) * @sin(C) -
        i * @cos(B) * @sin(C);
}

fn calculateZ(i: f32, j: f32, k: f32) f32 {
    return k * @cos(A) * @cos(B) - j * @sin(A) * @cos(B) + i * @sin(B);
}

fn calculateForSurface(cubeX: f32, cubeY: f32, cubeZ: f32, ch: u8) void {
    x = calculateX(cubeX, cubeY, cubeZ);
    y = calculateY(cubeX, cubeY, cubeZ);
    z = calculateZ(cubeX, cubeY, cubeZ) + @as(f32, @floatFromInt(distanceFromCam));

    ooz = 1.0 / z;

    xp = @intFromFloat(@as(f32, @floatFromInt(width)) / 2.0 + K1 * ooz * x * 2.0);
    yp = @intFromFloat(@as(f32, @floatFromInt(height)) / 2.0 + K1 * ooz * y);

    idx = xp + yp * width;
    if (idx >= 0 and idx < width * height) {
        const idx_usize: usize = @intCast(idx);
        if (ooz > zBuffer[idx_usize]) {
            zBuffer[idx_usize] = ooz;
            buffer[idx_usize] = ch;
        }
    }
}

pub fn main() !void {
    var stdout_buffer: [8192]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("\x1b[2J", .{});
    try stdout.flush();

    while (true) {
        @memset(&buffer, backgroundASCIICode);
        @memset(&zBuffer, 0);

        // Single cube centered on screen
        var cubeX: f32 = -cubeWidth;
        while (cubeX < cubeWidth) : (cubeX += incrementSpeed) {
            var cubeY: f32 = -cubeWidth;
            while (cubeY < cubeWidth) : (cubeY += incrementSpeed) {
                calculateForSurface(cubeX, cubeY, -cubeWidth, '@');
                calculateForSurface(cubeWidth, cubeY, cubeX, '$');
                calculateForSurface(-cubeWidth, cubeY, -cubeX, '~');
                calculateForSurface(-cubeX, cubeY, cubeWidth, '#');
                calculateForSurface(cubeX, -cubeWidth, -cubeY, ';');
                calculateForSurface(cubeX, cubeWidth, cubeY, '+');
            }
        }

        try stdout.print("\x1b[H", .{});

        var k: usize = 0;
        while (k < width * height) : (k += 1) {
            if (k % width == 0 and k != 0) {
                try stdout.writeByte('\n');
            }
            try stdout.writeByte(buffer[k]);
        }

        try stdout.flush();

        A += 0.05;
        B += 0.05;
        C += 0.01;

        std.Thread.sleep(16_000_000);
    }
}
