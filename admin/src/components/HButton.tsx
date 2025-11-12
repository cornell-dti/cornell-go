import styled, { css } from 'styled-components';

export const HButton = styled.div<{ float?: 'left' | 'right' }>`
  display: inline-block;
  height: 30px;
  user-select: none;
  line-height: 30px;
  transition: background-color 0.15s;
  color: #6200ee;
  padding: 0 10px 0 10px;
  border-radius: 4px;
  font-weight: 500;
  text-align: center;

  :hover {
    background-color: rgb(245, 245, 255);
  }

  :active {
    background-color: rgb(220, 220, 255);
  }

  ${props =>
    props.float &&
    css`
      float: ${props.float};
    `}
`;
