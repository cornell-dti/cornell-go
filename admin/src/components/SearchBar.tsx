import styled from "styled-components";

const SearchBarBox = styled.div`
  position: sticky;
  top: 0;
  border-radius: 4px;
  width: 100%;
  height: 48px;
  box-shadow: 0 0 2px black;
  margin-bottom: 12px;
  line-height: 30px;
  font-size: 18px;
  background-color: white;
  opacity: 0.9;
  z-index: 10;
`;

const SearchTextBox = styled.input`
  width: calc(50% - 12px);
  margin: 6px;
  font-size: 18px;
`;

const SearchBarText = styled.div`
  display: inline-block;
  width: calc(50% - 12px);
  font-weight: bold;
  text-align: center;
  font-size: 16px;
`;

export function SearchBar() {
  return (
    <SearchBarBox>
      <SearchTextBox placeholder="Search..."></SearchTextBox>
      <SearchBarText>No Event Selected</SearchBarText>
    </SearchBarBox>
  );
}
