import { cloneDeep } from 'lodash'

import { AskResponse, Citation } from '../../api'

export type ParsedAnswer = {
  citations: Citation[]
  markdownFormatText: string
  generated_chart: string | null
} | null

export const enumerateCitations = (citations: Citation[]) => {
  const filepathMap = new Map()
  for (const citation of citations) {
    const { filepath } = citation
    let part_i = 1
    if (filepathMap.has(filepath)) {
      part_i = filepathMap.get(filepath) + 1
    }
    filepathMap.set(filepath, part_i)
    citation.part_index = part_i
  }
  return citations
}

export function parseAnswer(answer: AskResponse): ParsedAnswer {
  if (typeof answer.answer !== 'string') return null
  let answerText = answer.answer

  // First try new format [1], [2], [3]
  let citationLinks = answerText.match(/\[(\d+)\]/g)
  let isNewFormat = true

  // If no matches, try old format [doc1], [doc2], [doc3]
  if (!citationLinks) {
    citationLinks = answerText.match(/\[(doc\d\d?\d?)]/g)
    isNewFormat = false
  }

  let filteredCitations = [] as Citation[]
  let citationReindex = 0

  citationLinks?.forEach(link => {
    let citationIndex: string

    if (isNewFormat) {
      // New format: [1] -> citationIndex = "1"
      citationIndex = link.slice(1, link.length - 1)
    } else {
      // Old format: [doc1] -> citationIndex = "1"
      const lengthDocN = '[doc'.length
      citationIndex = link.slice(lengthDocN, link.length - 1)
    }

    const citation = cloneDeep(answer.citations[Number(citationIndex) - 1]) as Citation
    if (!filteredCitations.find(c => c.id === citationIndex) && citation) {
      answerText = answerText.replaceAll(link, ` [${++citationReindex}] `)
      citation.id = citationIndex // original doc index to de-dupe
      citation.reindex_id = citationReindex.toString() // reindex from 1 for display
      filteredCitations.push(citation)
    }
  })

  filteredCitations = enumerateCitations(filteredCitations)

  return {
    citations: filteredCitations,
    markdownFormatText: answerText,
    generated_chart: answer.generated_chart
  }
}
