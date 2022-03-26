export function moveUp<T>(values: T[], index: number): T[] {
  return [
    ...values.slice(0, index - 1),
    values[index],
    ...values.slice(index - 1, index),
    ...values.slice(index + 1),
  ];
}

export function moveDown<T>(values: T[], index: number) {
  return [
    ...values.slice(0, index),
    ...values.slice(index + 1, index + 2),
    values[index],
    ...values.slice(index + 2),
  ];
}
