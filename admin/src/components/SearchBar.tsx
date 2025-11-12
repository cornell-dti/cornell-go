import { useContext, useRef } from 'react';
import styled from 'styled-components';
import { HButton } from './HButton';
import { ServerDataContext } from './ServerData';

const SearchBarBox = styled.div`
  display: flex;
  flex-direction: row;
  position: sticky;
  justify-content: space-between;
  top: 0;
  border-radius: 6px;
  width: 100%;
  height: 48px;
  box-shadow: 0 0 2px black;
  padding: 6px;
  margin-bottom: 12px;
  line-height: 30px;
  font-size: 18px;
  background-color: white;
  opacity: 0.9;
  z-index: 10;
`;

const SearchTextBox = styled.input`
  flex-shrink: 1;
  margin-left: 12px;
  width: calc(100% - 12px);
  font-size: 18px;
  justify-self: flex-end;
`;

const SearchBarText = styled.div`
  flex: 1;
  white-space: nowrap;
  text-overflow: ellipsis;
  overflow-x: clip;
  font-weight: bold;
  font-size: 16px;
  align-self: center;
  margin: 6px;
`;

const SearchBarButtons = styled.div`
  display: flex;
  flex-direction: row;
  align-self: center;
`;

export function SearchBar(props: {
  onSearch?: (query: string) => void;
  onCreate?: () => void;
}) {
  const searchRef = useRef<number>(-1);

  return (
    <SearchBarBox>
      <SearchBarButtons>
        <HButton onClick={props.onCreate}>Create</HButton>
      </SearchBarButtons>
      <SearchTextBox
        placeholder="Search..."
        onChange={e => {
          clearTimeout(searchRef.current);
          const val = e.target.value;
          searchRef.current = window.setTimeout(() => {
            if (props.onSearch) {
              props.onSearch(val);
            }
          }, 500);
        }}
      />
    </SearchBarBox>
  );
}
