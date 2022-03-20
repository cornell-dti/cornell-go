import { ReactNode, useLayoutEffect, useState } from "react";
import { createPortal } from "react-dom";
import styled, { css } from "styled-components";

const ModalBackground = styled.div<{ opacity: number }>`
  position: fixed;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.7);
  z-index: 999;
  transition: opacity 0.125s;

  ${(props) =>
    css`
      opacity: ${props.opacity};
    `}
`;

const ModalLayout = styled.div`
  position: relative;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 700px;
  border-radius: 5px;
  background-color: white;
  padding: 12px 18px 18px 18px;
  font-family: "Roboto";
`;

const ModalTitle = styled.div`
  font-weight: bold;
  font-size: 22px;
  margin-bottom: 12px;
  user-select: none;
`;

const ModalBody = styled.div`
  min-height: 150px;
  width: 100%;
  color: gray;
  font-size: 18px;
`;

const ModalButtonPanel = styled.div`
  height: 30px;
`;

const ModalButton = styled.div`
  float: right;
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
`;

export function Modal(props: {
  title: string;
  children: ReactNode;
  buttons: string[];
  isOpen: boolean;
  onButtonClick: (name: string) => void;
}) {
  const [open, setOpen] = useState(false);
  const [opacity, setOpacity] = useState(0);

  useLayoutEffect(() => {
    if (props.isOpen) {
      setOpen(true);
      setTimeout(() => {
        setOpacity(1);
      }, 0);
    } else {
      setOpacity(0);
      setTimeout(() => {
        setOpen(false);
      }, 125);
    }
  }, [props.isOpen, setOpen, setOpacity]);

  if (open) {
    return createPortal(
      <ModalBackground opacity={opacity}>
        <ModalLayout>
          <ModalTitle>{props.title}</ModalTitle>
          <ModalBody>{props.children}</ModalBody>
          <ModalButtonPanel>
            {props.buttons.map((btn) => (
              <ModalButton onClick={() => props.onButtonClick(btn)}>
                {btn}
              </ModalButton>
            ))}
          </ModalButtonPanel>
        </ModalLayout>
      </ModalBackground>,
      document.getElementById("modal-root")!
    );
  }
  return <></>;
}
