import styled from "styled-components";

export const ListCardBox = styled.div`
  position: relative;
  left: 50%;
  transform: translateX(-50%);
  border-radius: 6px;
  width: min(calc(100% - 40px), 600px);
  box-shadow: 0 0 2px 0.1px black;
  padding: 10px 10px 10px 12px;
  margin-bottom: 16px;
`;

export const ListCardTitle = styled.div`
  font-weight: 500;
  font-size: 22px;
  margin-bottom: 12px;
`;

export const ButtonSizer = styled.span`
  font-size: 16px;
`;

export const ListCardBody = styled.div`
  width: 100%;
  color: black;
  font-size: 16px;
`;

export const ListCardDescription = styled.div`
  padding-bottom: 12px;
  width: 100%;
  color: gray;
  font-size: 18px;
`;

export const ListCardButtons = styled.div`
  padding-top: 12px;
`;
