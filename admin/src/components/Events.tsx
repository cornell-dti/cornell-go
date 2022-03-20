import styled from "styled-components";
import { HButton } from "./HButton";

const EventCardBox = styled.div`
  position: relative;
  left: 50%;
  transform: translateX(-50%);
  border-radius: 4px;
  width: min(calc(100% - 40px), 600px);
  height: 400px;
  box-shadow: 0 0 2px black;
  padding: 10px 10px 10px 12px;
  margin-bottom: 16px;
  font-size: 18px;
`;

export function Events() {
  return (
    <>
      <EventCardBox>
        <b></b>
      </EventCardBox>
      <EventCardBox></EventCardBox>
    </>
  );
}
