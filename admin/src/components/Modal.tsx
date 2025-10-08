import { ReactNode, useLayoutEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import styled, { css } from 'styled-components';
import { HButton } from './HButton';

const ModalBackground = styled.div<{ opacity: number }>`
  position: fixed;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 999;
  transition: opacity 0.15s;
  overflow-y: auto;

  ${props => css`
    opacity: ${props.opacity};
  `}
`;

const ModalLayout = styled.div`
  position: relative;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: min(700px, calc(100% - 20px));
  border-radius: 5px;
  background-color: white;
  padding: 12px 18px 12px 18px;
  font-family: 'Roboto';
  box-shadow: 0 0 32px 0.1px rgb(80, 80, 80);
`;

const ModalTitle = styled.div`
  font-weight: 500;
  font-size: 22px;
  margin-bottom: 12px;
  user-select: none;
`;

const ModalBody = styled.div`
  min-height: 80px;
  width: 100%;
  color: gray;
  font-size: 18px;
  overflow-y: auto;
`;

const ModalButtonPanel = styled.div`
  height: 30px;
`;

export function Modal(props: {
  title: string;
  children: ReactNode;
  buttons: string[];
  isOpen: boolean;
  onButtonClick: (index: number) => void;
}) {
  const [open, setOpen] = useState(false);
  const [opacity, setOpacity] = useState(0);

  useLayoutEffect(() => {
    if (props.isOpen) {
      setOpen(true);
      const timeout = setTimeout(() => {
        setOpacity(1);
      }, 0);
      return () => clearTimeout(timeout);
    } else {
      setOpacity(0);
      const timeout = setTimeout(() => {
        setOpen(false);
      }, 150);
      return () => clearTimeout(timeout);
    }
  }, [props.isOpen, setOpen, setOpacity]);

  if (open) {
    return createPortal(
      <ModalBackground opacity={opacity}>
        <ModalLayout>
          <ModalTitle>{props.title}</ModalTitle>
          <ModalBody>{props.children}</ModalBody>
          <ModalButtonPanel>
            {props.buttons.map((btn, i) => (
              <HButton
                onClick={() => props.onButtonClick(i)}
                key={btn}
                float="right"
              >
                {btn}
              </HButton>
            ))}
          </ModalButtonPanel>
        </ModalLayout>
      </ModalBackground>,
      document.getElementById('modal-root')!,
    );
  }
  return <></>;
}
