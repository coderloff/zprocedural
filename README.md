# ZProcedural

## A very simple procedural generation algorithm written in Zig

### Task
In this procedural generation algorithm, we use three elements: 1x2 sections, 1x1 left rotation joints, and 1x1 right rotation joints. The goal is to select random start and end points, and connect this points using random elements after.

### Rules

- The path can not start or end with a joint
- Joints can not repeate: they can only be placed between sections
- The algorithm should change its decision if entered wrong path