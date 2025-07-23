import { CommandBarButton, DefaultButton, IButtonProps } from '@fluentui/react'

import styles from './Button.module.css'

interface ButtonProps extends IButtonProps {
  onClick: () => void
  text: string | undefined
}

export const ShareButton: React.FC<ButtonProps> = ({ onClick, text }) => {
  return (
    <CommandBarButton
      className={styles.shareButtonRoot}
      iconProps={{ iconName: 'Share' }}
      onClick={onClick}
      text={text}
    />
  )
}

export const HistoryButton: React.FC<ButtonProps> = ({ onClick, text }) => {
  return (
    <DefaultButton
      className={styles.historyButtonRoot}
      text={text}
      iconProps={{ iconName: 'History' }}
      onClick={onClick}
    />
  )
}

export const FeedbackButton: React.FC<ButtonProps> = ({ onClick, text }) => {
  return (
    <DefaultButton
      className={styles.feedbackButtonRoot}
      text={text}
      iconProps={{ iconName: 'Feedback' }}
      onClick={onClick}
    />
  )
}

export const FindOutMoreButton: React.FC<ButtonProps> = ({ onClick, text }) => {
  return (
    <DefaultButton
      className={styles.findOutMoreButtonRoot}
      text={text}
      iconProps={{ iconName: 'Info' }}
      onClick={onClick}
    />
  )
}
