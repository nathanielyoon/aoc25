import input from "./inputs/1.txt" with { type: "text" };
import example from "./examples/1.txt" with { type: "text" };

// https://dev.mozilla.org/Web/JavaScript/Reference/Operators/Remainder
const mod = ($: number) => ($ % 100 + 100) % 100;

const solve1 = (input: string) => {
  let state = 50, count = 0;
  for (const [, side, size] of input.matchAll(/([LR])(\d+)/g)) {
    state = mod(state + (side === "L" ? -size : +size));
    if (state === 0) ++count;
  }
  return count;
};
console.assert(solve1(example) === 3);

const solve2 = (input: string) => {
  let state = 50, count = 0;
  for (const [, side, size] of input.matchAll(/([LR])(\d+)/g)) {
    let temp = +size;
    while (temp > 100) ++count, temp -= 100;
    state = side === "L" ? (state || 100) - temp : state + temp;
    state = mod(temp = state);
    if (state === 0 || state !== temp) ++count;
  }
  return count;
};
console.assert(solve2(example) === 6);

import.meta.main && console.log(`${solve1(input)}\n${solve2(input)}`);
