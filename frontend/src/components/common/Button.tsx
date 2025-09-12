import { CommandBarButton, DefaultButton, IButtonProps } from '@fluentui/react'
import { ShareRegular, ClockRegular, CommentRegular, InfoRegular } from '@fluentui/react-icons'

import styles from './Button.module.css'

interface ButtonProps {
  onClick: () => void
  text: string | undefined
}

export const ShareButton: React.FC<ButtonProps> = ({ onClick, text }) => {
  return (
    <CommandBarButton
      className={styles.shareButtonRoot}
      onClick={onClick}
      text={text}
      onRenderIcon={() => <ShareRegular style={{ width: 16, height: 16 }} />}
    />
  )
}

export const HistoryButton: React.FC<ButtonProps> = ({ onClick, text }) => {
  return (
    <DefaultButton
      className={styles.historyButtonRoot}
      text={text}
      onClick={onClick}
      onRenderIcon={() => <ClockRegular style={{ width: 16, height: 16 }} />}
    />
  )
}

export const FeedbackButton: React.FC<ButtonProps> = ({ onClick, text }) => {
  return (
    <DefaultButton
      className={styles.feedbackButtonRoot}
      text={text}
      onClick={onClick}
      onRenderIcon={() => <CommentRegular style={{ width: 16, height: 16 }} />}
    />
  )
}

export const FindOutMoreButton: React.FC<ButtonProps> = ({ onClick, text }) => {
  return (
    <DefaultButton
      className={styles.findOutMoreButtonRoot}
      text={text}
      onClick={onClick}
      onRenderIcon={() => <InfoRegular style={{ width: 16, height: 16 }} />}
    />
  )
}
