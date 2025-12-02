import input from "./inputs/2.txt" with { type: "text" };
import example from "./examples/2.txt" with { type: "text" };

const solve = (pattern: RegExp) => (input: string) =>
  input.matchAll(/(\d+)-(\d+)/g).reduce((sum, match) => {
    const min = +match[1], max = +match[2];
    for (let z = min; z <= max; ++z) if (pattern.test(`${z}`)) sum += z;
    return sum;
  }, 0);

const solve1 = solve(/^(\d+)\1$/);
console.assert(solve1(example) === 1227775554);

const solve2 = solve(/^(\d+)\1+$/);
console.assert(solve2(example) === 4174379265);

import.meta.main && console.log(`${solve1(input)}\n${solve2(input)}`);
