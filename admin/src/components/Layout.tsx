import { faBars, faTimes } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { createContext, ReactNode, useContext, useState } from 'react';
import styled, { css } from 'styled-components';

const SidebarShowContext = createContext({
  shown: false,
  toggleShow: () => {},
});

const AppBarBase = styled.div`
  position: absolute;
  z-index: 99;
  background-color: #6200ee;
  width: 100%;
  height: 60px;
  box-shadow: 0px 0.1px 1px black;
  color: white;
  padding: 10px 10px 10px 20px;
  line-height: 40px;
  font-size: 24px;
  user-select: none;
`;

const AppBarButton = styled.div`
  display: inline-block;
  width: 32px;
  margin-right: 30px;

  @media (min-width: 768px) {
    display: none;
  }
`;

export function AppBar(props: { children: ReactNode }) {
  const showCtxt = useContext(SidebarShowContext);
  return (
    <AppBarBase>
      <AppBarButton onClick={() => showCtxt.toggleShow()}>
        <FontAwesomeIcon icon={showCtxt.shown ? faTimes : faBars} />
      </AppBarButton>
      {props.children}
    </AppBarBase>
  );
}

const SidebarBase = styled.div<{ shown: boolean }>`
  position: absolute;
  padding-top: 60px;
  z-index: 98;
  width: 240px;
  height: 100%;
  box-shadow: 0.5px 0 1px black;
  overflow-y: auto;
  transition: left 0.25s;
  background-color: white;

  @media (max-width: 768px) {
    left: -100%;
    width: 100%;

    ${props =>
      props.shown &&
      css`
        left: 0px;
      `}
  }
`;

export function Sidebar(props: { children: ReactNode }) {
  const showCtxt = useContext(SidebarShowContext);

  return <SidebarBase shown={showCtxt.shown}>{props.children}</SidebarBase>;
}

export const Container = styled.div`
  position: absolute;
  z-index: 0;

  @media (min-width: 768px) {
    left: 240px;
    width: calc(100% - 240px);
  }
  @media (max-width: 768px) {
    width: 100%;
  }
  top: 60px;
  height: calc(100% - 60px);
  padding: 15px 15px 0 15px;
  overflow-y: auto;
`;

const AppLayoutBase = styled.div`
  width: 100%;
  height: 100%;
  font-family: Roboto;
`;

export function AppLayout(props: { children: ReactNode }) {
  const [shown, setShown] = useState(false);

  return (
    <SidebarShowContext.Provider
      value={{
        shown,
        toggleShow: () => setShown(!shown),
      }}
    >
      <AppLayoutBase>{props.children}</AppLayoutBase>
    </SidebarShowContext.Provider>
  );
}

const SidebarButtonBase = styled.div<{ active?: boolean }>`
  width: 100%;
  height: 42px;
  user-select: none;
  line-height: 42px;
  padding-left: 16px;
  transition: background-color 0.15s;

  :hover {
    background-color: rgb(240, 240, 255);
  }

  :active {
    background-color: rgb(220, 220, 255);
  }

  ${props =>
    props.active &&
    css`
      background-color: rgb(240, 240, 255);
    `}
`;

export function SidebarButton(props: {
  children: ReactNode;
  active: boolean;
  onClick: () => void;
}) {
  const showCtxt = useContext(SidebarShowContext);
  return (
    <SidebarButtonBase
      onClick={() => {
        props.onClick();
        showCtxt.toggleShow();
      }}
      active={props.active}
    >
      {props.children}
    </SidebarButtonBase>
  );
}
