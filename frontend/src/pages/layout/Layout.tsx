import { useContext, useEffect, useState } from 'react'
import { Link, Outlet } from 'react-router-dom'
import { Dialog, Stack, TextField } from '@fluentui/react'
import { CopyRegular } from '@fluentui/react-icons'

import { CosmosDBStatus } from '../../api'
import Contoso from '../../assets/Contoso.svg'
import ForceLogo from '../../assets/ForceLogo.svg'
import { HistoryButton, ShareButton, FeedbackButton, FindOutMoreButton } from '../../components/common/Button'
import { AppStateContext } from '../../state/AppProvider'

import styles from './Layout.module.css'

const Layout = () => {
  const [isSharePanelOpen, setIsSharePanelOpen] = useState<boolean>(false)
  const [copyClicked, setCopyClicked] = useState<boolean>(false)
  const [copyText, setCopyText] = useState<string>('Copy URL')
  const [shareLabel, setShareLabel] = useState<string | undefined>('Share')
  const [hideHistoryLabel, setHideHistoryLabel] = useState<string>('Hide chat history')
  const [showHistoryLabel, setShowHistoryLabel] = useState<string>('Show chat history')
  const [feedbackLabel, setFeedbackLabel] = useState<string>('Send Feedback')
  const [logo, setLogo] = useState('')
  const [forceLogo, setForceLogo] = useState('')
  const appStateContext = useContext(AppStateContext)
  const ui = appStateContext?.state.frontendSettings?.ui

  const handleShareClick = () => {
    setIsSharePanelOpen(true)
  }

  const handleSharePanelDismiss = () => {
    setIsSharePanelOpen(false)
    setCopyClicked(false)
    setCopyText('Copy URL')
  }

  const handleCopyClick = () => {
    navigator.clipboard.writeText(window.location.href)
    setCopyClicked(true)
  }

  const handleHistoryClick = () => {
    appStateContext?.dispatch({ type: 'TOGGLE_CHAT_HISTORY' })
  }

  const handleFeedbackClick = () => {
    const feedbackEmail = ui?.feedback_email
    if (feedbackEmail) {
      const subject = encodeURIComponent('CoPPA Stop & Search Feedback')
      const body = encodeURIComponent('Hi,\n\nI would like to provide feedback about CoPPA Stop & Search:\n\n\n\nThank you.')
      const mailtoUrl = `mailto:${feedbackEmail}?subject=${subject}&body=${body}`
      window.open(mailtoUrl, '_blank')
    }
  }

  const handleFindOutMoreClick = () => {
    const findOutMoreLink = ui?.find_out_more_link
    if (findOutMoreLink) {
      window.open(findOutMoreLink, '_blank')
    }
  }

  useEffect(() => {
    if (!appStateContext?.state.isLoading) {
      console.log('=== DEBUGGING INFO ===')
      console.log('UI object:', ui)
      console.log('Police force logo:', ui?.police_force_logo)
      console.log('Police force tagline:', ui?.police_force_tagline)
      console.log('Police force tagline 2:', ui?.police_force_tagline_2)
      console.log('Force logo state will be:', ui?.police_force_logo || ForceLogo)
      console.log('=== END DEBUG ===')

      setLogo(ui?.logo || Contoso)
      // Set the force logo from environment variable or fallback to default
      setForceLogo(ui?.police_force_logo || ForceLogo)
    }
  }, [appStateContext?.state.isLoading, ui])

  useEffect(() => {
    if (copyClicked) {
      setCopyText('Copied URL')
    }
  }, [copyClicked])

  useEffect(() => {}, [appStateContext?.state.isCosmosDBAvailable.status])

  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth < 480) {
        setShareLabel(undefined)
        setHideHistoryLabel('Hide history')
        setShowHistoryLabel('Show history')
        setFeedbackLabel('Feedback')
      } else {
        setShareLabel('Share')
        setHideHistoryLabel('Hide chat history')
        setShowHistoryLabel('Show chat history')
        setFeedbackLabel('Send Feedback')
      }
    }

    window.addEventListener('resize', handleResize)
    handleResize()

    return () => window.removeEventListener('resize', handleResize)
  }, [])

  return (
    <div className={styles.layout}>
      <header className={styles.header} role={'banner'}>
        <div className={styles.headerContainer}>
          <div className={styles.headerLeftLogo}>
            {/* College of Policing logo positioned on the far left */}
            <img src={logo} className={styles.headerIcon} aria-hidden="true" alt="" />
            <div className={styles.buttonStack}>
              {ui?.feedback_email && <FeedbackButton onClick={handleFeedbackClick} text={feedbackLabel} />}
              {ui?.find_out_more_link && <FindOutMoreButton onClick={handleFindOutMoreClick} text="Find out more" />}
            </div>
          </div>
          <div className={styles.headerCenterContent}>
            <Link to="/" style={{ textDecoration: 'none' }}>
              <h1 className={styles.headerTitle}>CoPPA Stop & Search</h1>
              <p className={styles.headerSubtitle}>
                CoPPA Stop & Search is specialized to assist supervisors with reasonable grounds assessment based on PACE Code A and College of Policing guidance
              </p>
            </Link>
          </div>
          <div className={styles.headerRightContainer}>
            {appStateContext?.state.isCosmosDBAvailable?.status !== CosmosDBStatus.NotConfigured &&
              ui?.show_chat_history_button !== false && (
                <HistoryButton
                  onClick={handleHistoryClick}
                  text={appStateContext?.state?.isChatHistoryOpen ? hideHistoryLabel : showHistoryLabel}
                />
              )}
            {/* Police Force logo displayed when configured */}
            {forceLogo && <img src={forceLogo} className={styles.forceLogo} aria-hidden="true" alt="Force Logo" />}
          </div>
        </div>
      </header>
      <Outlet />
      <Dialog
        onDismiss={handleSharePanelDismiss}
        hidden={!isSharePanelOpen}
        styles={{
          main: [
            {
              selectors: {
                ['@media (min-width: 480px)']: {
                  maxWidth: '600px',
                  background: '#FFFFFF',
                  boxShadow: '0px 14px 28.8px rgba(0, 0, 0, 0.24), 0px 0px 8px rgba(0, 0, 0, 0.2)',
                  borderRadius: '8px',
                  maxHeight: '200px',
                  minHeight: '100px'
                }
              }
            }
          ]
        }}
        dialogContentProps={{
          title: 'Share the web app',
          showCloseButton: true
        }}>
        <Stack horizontal verticalAlign="center" style={{ gap: '8px' }}>
          <TextField className={styles.urlTextBox} defaultValue={window.location.href} readOnly />
          <div
            className={styles.copyButtonContainer}
            role="button"
            tabIndex={0}
            aria-label="Copy"
            onClick={handleCopyClick}
            onKeyDown={e => (e.key === 'Enter' || e.key === ' ' ? handleCopyClick() : null)}>
            <CopyRegular className={styles.copyButton} />
            <span className={styles.copyButtonText}>{copyText}</span>
          </div>
        </Stack>
      </Dialog>
    </div>
  )
}

export default Layout
