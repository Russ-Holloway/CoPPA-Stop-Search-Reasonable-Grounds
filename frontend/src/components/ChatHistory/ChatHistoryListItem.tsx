import { useContext, useState, useRef, useEffect } from 'react'
import * as React from 'react'
import { List, Separator, Spinner, SpinnerSize, Stack, Text } from '@fluentui/react'

import { historyList } from '../../api'
import { Conversation } from '../../api/models'
import { AppStateContext } from '../../state/AppProvider'

import { GroupedChatHistory } from './ChatHistoryList'

import styles from './ChatHistoryPanel.module.css'

interface ChatHistoryListItemCellProps {
  item?: Conversation
  onSelect: (item: Conversation | null) => void
}

interface ChatHistoryListItemGroupsProps {
  groupedChatHistory: GroupedChatHistory[]
}

const formatMonth = (month: string) => {
  const currentDate = new Date()
  const currentYear = currentDate.getFullYear()

  const [monthName, yearString] = month.split(' ')
  const year = parseInt(yearString)

  if (year === currentYear) {
    return monthName
  } else {
    return month
  }
}

export const ChatHistoryListItemCell: React.FC<ChatHistoryListItemCellProps> = ({ item, onSelect }) => {
  const [isHovered, setIsHovered] = useState(false)
  const appStateContext = useContext(AppStateContext)
  const isSelected = item?.id === appStateContext?.state.currentChat?.id

  if (!item) {
    return null
  }

  const handleSelectItem = () => {
    onSelect(item)
    appStateContext?.dispatch({ type: 'UPDATE_CURRENT_CHAT', payload: item })
  }

  const truncatedTitle = item?.title?.length > 28 ? `${item.title.substring(0, 28)} ...` : item.title

  return (
    <Stack
      key={item.id}
      tabIndex={0}
      aria-label="chat history item"
      className={styles.itemCell}
      onClick={() => handleSelectItem()}
      onKeyDown={e => (e.key === 'Enter' || e.key === ' ' ? handleSelectItem() : null)}
      verticalAlign="center"
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      styles={{
        root: {
          backgroundColor: isSelected ? '#e6e6e6' : 'transparent'
        }
      }}>
      <Stack.Item style={{ width: '100%' }}>
        <Stack horizontal verticalAlign={'center'} style={{ width: '100%' }}>
          <div className={styles.chatTitle}>{truncatedTitle}</div>
          {item.status === 'completed' && (
            <div
              style={{
                marginLeft: 'auto',
                fontSize: '10px',
                color: '#666',
                opacity: 0.7
              }}>
              ✓
            </div>
          )}
        </Stack>
      </Stack.Item>
    </Stack>
  )
}

export const ChatHistoryListItemGroups: React.FC<ChatHistoryListItemGroupsProps> = ({ groupedChatHistory }) => {
  const appStateContext = useContext(AppStateContext)
  const observerTarget = useRef(null)
  const [, setSelectedItem] = useState<Conversation | null>(null)
  const [offset, setOffset] = useState<number>(25)
  const [observerCounter, setObserverCounter] = useState(0)
  const [showSpinner, setShowSpinner] = useState(false)
  const firstRender = useRef(true)

  const handleSelectHistory = (item?: Conversation) => {
    if (item) {
      setSelectedItem(item)
    }
  }

  const onRenderCell = (item?: Conversation) => {
    return <ChatHistoryListItemCell item={item} onSelect={() => handleSelectHistory(item)} />
  }

  useEffect(() => {
    if (firstRender.current) {
      firstRender.current = false
      return
    }
    handleFetchHistory()
    setOffset(offset => (offset += 25))
  }, [observerCounter])

  const handleFetchHistory = async () => {
    const currentChatHistory = appStateContext?.state.chatHistory
    setShowSpinner(true)

    await historyList(offset).then(response => {
      const concatenatedChatHistory = currentChatHistory && response && currentChatHistory.concat(...response)
      if (response) {
        appStateContext?.dispatch({ type: 'FETCH_CHAT_HISTORY', payload: concatenatedChatHistory || response })
      } else {
        appStateContext?.dispatch({ type: 'FETCH_CHAT_HISTORY', payload: null })
      }
      setShowSpinner(false)
      return response
    })
  }

  useEffect(() => {
    const observer = new IntersectionObserver(
      entries => {
        if (entries[0].isIntersecting) setObserverCounter(observerCounter => (observerCounter += 1))
      },
      { threshold: 1 }
    )

    if (observerTarget.current) observer.observe(observerTarget.current)

    return () => {
      if (observerTarget.current) observer.unobserve(observerTarget.current)
    }
  }, [observerTarget])

  return (
    <div className={styles.listContainer} data-is-scrollable>
      {groupedChatHistory.map(
        group =>
          group.entries.length > 0 && (
            <Stack
              horizontalAlign="start"
              verticalAlign="center"
              key={group.month}
              className={styles.chatGroup}
              aria-label={`chat history group: ${group.month}`}>
              <Stack aria-label={group.month} className={styles.chatMonth}>
                {formatMonth(group.month)}
              </Stack>
              <List
                aria-label={`chat history list`}
                items={group.entries}
                onRenderCell={onRenderCell}
                className={styles.chatList}
              />
              <div ref={observerTarget} />
              <Separator
                styles={{
                  root: {
                    width: '100%',
                    position: 'relative',
                    '::before': {
                      backgroundColor: '#d6d6d6'
                    }
                  }
                }}
              />
            </Stack>
          )
      )}
      {showSpinner && (
        <div className={styles.spinnerContainer}>
          <Spinner size={SpinnerSize.small} aria-label="loading more chat history" className={styles.spinner} />
        </div>
      )}
    </div>
  )
}
