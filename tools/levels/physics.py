"""Frame-accurate copy of the Spark's movement in World 1 (scripts/world1/w1_sim.gd).
It started as a copy of scripts/player.gd. World 1 adds a softer wall kick and
slowing down in the air when no direction is held.

Numbers come from RunState.BASE and player.gd. If those change, change them
here too: the level maps are only proven against these values.
"""
from dataclasses import dataclass, replace

DT = 1.0 / 60.0
TILE = 16

MAX_RUN = 135.0
ACCEL = 1150.0
AIR_ACCEL = 780.0
FRICTION = 1500.0
GRAVITY = 920.0
JUMP_VEL = 325.0
SHORT_HOP = 0.45
COYOTE = 0.10
BUFFER = 0.12
MAX_FALL = 390.0
DASH_SPEED = 340.0
DASH_TIME = 0.13
DASH_EXIT = 170.0
OVERSPEED_DECAY = 350.0
WALL_SLIDE = 60.0
WALL_GRACE = 0.12
HALF_W = 6.0
HALF_H = 7.0
STOMP_BOUNCE = 230.0
STOMP_GRACE = 6      # frames after a stomp when pressing jump still bounces high
STOMP_DEPTH = 14.0   # a falling Spark this deep into an enemy's top still stomps it (hoppers rise to meet you)
SPRING_POWER = 500.0
# After a wall kick, input is locked away from the wall for this long, as in
# Celeste. Without it one wall can be climbed by kicking and steering back.
KICK_LOCK = 0.16
KICK_X = 1.0           # kick speed away from the wall, times MAX_RUN (player.gd: 1.15)
AIR_FRICTION = 500.0   # px/s/s slowdown in the air with no direction held (not during a kick lock)
# World 3 wind: side wind pushes up to WIND_MAX, an updraft lifts up to RISE_MAX
WIND_SIDE = 900.0
WIND_MAX = 190.0
WIND_UP = 1600.0
RISE_MAX = 210.0


@dataclass(frozen=True)
class Body:
    x: float
    y: float
    vx: float = 0.0
    vy: float = 0.0
    floor: bool = False
    coyote: float = 0.0
    buffer: float = 0.0
    held: bool = False
    face: int = 1
    dash_t: float = 0.0
    dash_dir: int = 1
    dash_ready: bool = True
    wall_grace: float = 0.0
    wall_dir: int = 0
    wall_top: float = 0.0
    spring_t: float = 0.0
    on_wall: bool = False
    kick_t: float = 0.0


def step(b: Body, dir_: int, jump: bool, dash: bool, world, down: bool = False) -> Body:
    """One physics frame. `world.move` resolves collisions."""
    kick_t = max(0.0, b.kick_t - DT)
    if kick_t > 0.0 and dir_ != 0:
        dir_ = b.face  # locked away from the wall
    spring_t = max(0.0, b.spring_t - DT)
    buffer = max(0.0, b.buffer - DT)
    coyote = max(0.0, b.coyote - DT)
    wall_grace = max(0.0, b.wall_grace - DT)
    if jump and not b.held:
        buffer = BUFFER
    held = jump
    vx, vy = b.vx, b.vy
    face = b.face
    dash_t, dash_dir, dash_ready = b.dash_t, b.dash_dir, b.dash_ready
    accel = ACCEL if b.floor else AIR_ACCEL

    if dash_t > 0.0:
        dash_t -= DT
        vx = dash_dir * DASH_SPEED
        vy = 0.0
        if dash_t <= 0.0:
            vx = dash_dir * DASH_EXIT
    else:
        if dir_ > 0:
            vx = max(MAX_RUN, vx - OVERSPEED_DECAY * DT) if vx > MAX_RUN else min(MAX_RUN, vx + accel * DT)
        elif dir_ < 0:
            vx = min(-MAX_RUN, vx + OVERSPEED_DECAY * DT) if vx < -MAX_RUN else max(-MAX_RUN, vx - accel * DT)
        elif b.floor:
            f = FRICTION * DT
            vx = 0.0 if abs(vx) <= f else vx - (1 if vx > 0 else -1) * f
        elif AIR_FRICTION > 0.0 and kick_t <= 0.0:
            f = AIR_FRICTION * DT
            vx = 0.0 if abs(vx) <= f else vx - (1 if vx > 0 else -1) * f
        else:
            vx *= (1.0 - 0.4 * DT)

    if b.floor:
        coyote = COYOTE
    # Down + jump on a thin girder drops through it instead of jumping
    # (w1_sim.gd step_player). The feet end up below the girder's top, and
    # one-way tiles only catch feet that were above them.
    drop_y = 0.0
    if down and buffer > 0.0 and b.floor and world.on_girder_only(b.x, b.y):
        drop_y = 3.0
        vy = 0.0
        coyote = 0.0
        buffer = 0.0
    jumped = False
    if buffer > 0.0 and coyote > 0.0 and not (spring_t > 0.0 and vy < 0.0):
        vy = -JUMP_VEL
        buffer = 0.0
        coyote = 0.0
        jumped = True
    if not held and spring_t <= 0.0 and dash_t <= 0.0 and vy < -JUMP_VEL * SHORT_HOP:
        vy = -JUMP_VEL * SHORT_HOP

    if buffer > 0.0 and not b.floor and wall_grace > 0.0 and dash_t <= 0.0 \
            and b.y + HALF_H >= b.wall_top - 4.0:
        vy = -JUMP_VEL * 0.95
        vx = -b.wall_dir * MAX_RUN * KICK_X
        buffer = 0.0
        coyote = 0.0
        wall_grace = 0.0
        face = -b.wall_dir
        kick_t = KICK_LOCK

    if dash and dash_ready and dash_t <= 0.0:
        dash_t = DASH_TIME
        dash_ready = False
        dash_dir = dir_ if dir_ != 0 else face
        face = dash_dir
        vy = 0.0

    if dash_t <= 0.0:
        vy = min(MAX_FALL, vy + GRAVITY * DT)

    if not b.floor and b.on_wall and vy > 0.0 and dash_t <= 0.0 and dir_ != 0 and dir_ == b.wall_dir:
        vy = min(vy, WALL_SLIDE)

    # wind (a dash cuts straight through it)
    ax, ay = world.wind_at(b.x, b.y)
    if dash_t <= 0.0:
        if ax > 0.0 and vx < WIND_MAX:
            vx = min(WIND_MAX, vx + ax * DT)
        elif ax < 0.0 and vx > -WIND_MAX:
            vx = max(-WIND_MAX, vx + ax * DT)
        if ay < 0.0 and vy > -RISE_MAX:
            vy = max(-RISE_MAX, vy + ay * DT)

    x, y, floor, on_wall, wall_dir, wall_top, vx, vy = world.move(b.x, b.y + drop_y, vx, vy)

    if dir_ != 0 and kick_t <= 0.0:
        face = dir_
    if floor:
        coyote = COYOTE
        dash_ready = True
        wall_grace = 0.0
    elif on_wall:
        wall_grace = WALL_GRACE
    return Body(x, y, vx, vy, floor, coyote, buffer, held, face, dash_t, dash_dir,
                dash_ready, wall_grace, wall_dir if on_wall else b.wall_dir,
                wall_top if on_wall else b.wall_top, spring_t, on_wall, kick_t)


class FlatWorld:
    """Open floor at y=0 with optional ledge, for measuring the jump envelope."""

    def __init__(self, floor_to=0.0):
        self.floor_to = floor_to  # floor exists for x < floor_to

    def move(self, x, y, vx, vy):
        nx = x + vx * DT
        ny = y + vy * DT
        floor = False
        if vy >= 0 and ny + HALF_H >= 0.0 and y + HALF_H <= 0.0 + 0.01 and nx - HALF_W < self.floor_to:
            ny = -HALF_H
            vy = 0.0
            floor = True
        return nx, ny, floor, False, 0, 0.0, vx, vy
