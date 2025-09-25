export async function postRequest<TBody, TResponse>(
  route: string,
  body: TBody,
): Promise<TResponse> {
  const resp = await fetch(route, {
    method: "post",
    mode: "cors",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  const text = await resp.text();

  return text && JSON.parse(text);
}
