import { useState, useRef, useEffect } from 'react'
import { Stack, TextField, ITextField } from '@fluentui/react'
import { ArrowEnterRegular, ArrowEnterFilled } from '@fluentui/react-icons'

import styles from './QuestionInput.module.css'
import './QuestionInputOverrides.css'
import { ChatMessage } from '../../api'

interface Props {
  onSend: (question: ChatMessage['content'], id?: string) => void
  disabled: boolean
  placeholder?: string
  clearOnSend?: boolean
  conversationId?: string
}

export const QuestionInput = ({ onSend, disabled, placeholder, clearOnSend, conversationId }: Props) => {
  const [question, setQuestion] = useState<string>('')
  const [hasError, setHasError] = useState<boolean>(false)
  const [errorMessage, setErrorMessage] = useState<string>('')
  const [statusMessage, setStatusMessage] = useState<string>('')
  const textAreaRef = useRef<ITextField>(null)

  // Clear error when user starts typing
  useEffect(() => {
    if (question.trim() && hasError) {
      setHasError(false)
      setErrorMessage('')
    }
  }, [question, hasError])

  const sendQuestion = () => {
    if (disabled) {
      setStatusMessage('Cannot send message while processing')
      return
    }

    if (!question.trim()) {
      setHasError(true)
      setErrorMessage('Please enter a question before sending')
      setStatusMessage('Error: Question cannot be empty')
      textAreaRef.current?.focus()
      return
    }

    const questionTest: ChatMessage['content'] = question.toString()

    if (conversationId && questionTest !== undefined) {
      onSend(questionTest, conversationId)
    } else {
      onSend(questionTest)
    }

    if (clearOnSend) {
      setQuestion('')
    }

    setStatusMessage('Question sent successfully')
    setHasError(false)
    setErrorMessage('')

    // Clear status message after 3 seconds
    setTimeout(() => {
      setStatusMessage('')
    }, 3000)
  }

  const onEnterPress = (ev: React.KeyboardEvent<Element>) => {
    if (ev.key === 'Enter' && !ev.shiftKey && !(ev.nativeEvent?.isComposing === true)) {
      ev.preventDefault()
      sendQuestion()
    }
  }

  const onQuestionChange = (_ev: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>, newValue?: string) => {
    setQuestion(newValue || '')
  }

  const sendQuestionDisabled = disabled || !question.trim()

  return (
    <Stack horizontal className={styles.questionInputContainer}>
      {/* Screen reader only status announcements */}
      <div aria-live="polite" aria-atomic="true" className={styles.srOnly}>
        {statusMessage}
      </div>

      <TextField
        componentRef={textAreaRef}
        className={styles.questionInputTextArea}
        placeholder={placeholder}
        multiline
        resizable={false}
        borderless
        value={question}
        onChange={onQuestionChange}
        onKeyDown={onEnterPress}
        aria-invalid={hasError}
        aria-describedby={hasError ? 'question-error' : undefined}
        aria-label="Type your question here"
      />

      {hasError && (
        <div id="question-error" role="alert" aria-live="assertive" className={styles.errorMessage}>
          {errorMessage}
        </div>
      )}

      <div
        className={styles.questionInputSendButtonContainer}
        role="button"
        tabIndex={0}
        aria-label={sendQuestionDisabled ? 'Send button disabled' : 'Send question'}
        aria-disabled={sendQuestionDisabled}
        onClick={sendQuestion}
        onKeyDown={e => (e.key === 'Enter' || e.key === ' ' ? sendQuestion() : null)}>
        {sendQuestionDisabled ? (
          <ArrowEnterRegular className={styles.questionInputSendButtonDisabled} aria-hidden="true" />
        ) : (
          <ArrowEnterFilled className={styles.questionInputSendButton} title="Press Enter to send" aria-hidden="true" />
        )}
      </div>
      <div className={styles.questionInputBottomBorder} />
    </Stack>
  )
}
