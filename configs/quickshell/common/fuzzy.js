.pragma library

const MATCH = 16
const CONSEC = 20
const BOUNDARY = 24
const FIRST = 14
const CASE = 3
const GAP = 3
const LEAD = 3
const LEAD_CAP = 20
const NEG = -1e9

function isBoundary(text, i) {
    if (i === 0)
        return true
    const p = text.charAt(i - 1)
    if (p === " " || p === "-" || p === "_" || p === "." || p === "/" || p === ":")
        return true
    const c = text.charAt(i)
    return p === p.toLowerCase() && p !== p.toUpperCase()
        && c === c.toUpperCase() && c !== c.toLowerCase()
}

// subsequence match with word-boundary / adjacency bonuses.
// returns { score, positions } or null. positions index into `text`
function match(text, query) {
    if (!text)
        return null
    if (query.length === 0)
        return { score: 0, positions: [] }

    const tl = text.toLowerCase()
    const ql = query.toLowerCase()
    const n = tl.length
    const m = ql.length
    if (m > n)
        return null

    // cheap reject before paying for the dp table
    let k = 0
    for (let j = 0; j < n && k < m; j++)
        if (tl.charCodeAt(j) === ql.charCodeAt(k)) k++
    if (k < m)
        return null

    const score = []
    const par = []
    for (let i = 0; i < m; i++) {
        score.push(new Array(n).fill(NEG))
        par.push(new Array(n).fill(-1))
    }

    for (let i = 0; i < m; i++) {
        // best predecessor seen so far, decayed once per skipped char
        let run = NEG
        let runJ = -1
        for (let j = i; j < n; j++) {
            if (i > 0 && j > 0) {
                if (run > NEG) run -= GAP
                if (score[i - 1][j - 1] > run) {
                    run = score[i - 1][j - 1]
                    runJ = j - 1
                }
            }
            if (tl.charCodeAt(j) !== ql.charCodeAt(i))
                continue

            let base = MATCH
            if (isBoundary(text, j)) base += BOUNDARY
            if (j === 0) base += FIRST
            if (text.charCodeAt(j) === query.charCodeAt(i)) base += CASE

            if (i === 0) {
                score[i][j] = base - Math.min(j * LEAD, LEAD_CAP)
            } else {
                const consec = score[i - 1][j - 1] > NEG ? score[i - 1][j - 1] + CONSEC : NEG
                if (consec >= run && consec > NEG) {
                    score[i][j] = consec + base
                    par[i][j] = j - 1
                } else if (run > NEG) {
                    score[i][j] = run + base
                    par[i][j] = runJ
                }
            }
        }
    }

    let best = NEG
    let bestJ = -1
    for (let j = m - 1; j < n; j++) {
        if (score[m - 1][j] > best) {
            best = score[m - 1][j]
            bestJ = j
        }
    }
    if (bestJ === -1)
        return null

    const positions = new Array(m)
    let j = bestJ
    for (let i = m - 1; i >= 0; i--) {
        positions[i] = j
        j = par[i][j]
    }

    // shorter names win ties, so "Files" beats "Recent Files Indexer"
    return { score: best - n * 0.4, positions: positions }
}

function escape(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
}

// StyledText markup with matched chars painted in `color`
function highlight(text, positions, color) {
    if (!positions || positions.length === 0)
        return escape(text)
    let out = ""
    let pi = 0
    let inSpan = false
    for (let i = 0; i < text.length; i++) {
        const hit = pi < positions.length && positions[pi] === i
        if (hit && !inSpan) {
            out += "<font color=\"" + color + "\">"
            inSpan = true
        } else if (!hit && inSpan) {
            out += "</font>"
            inSpan = false
        }
        if (hit) pi++
        out += escape(text.charAt(i))
    }
    if (inSpan) out += "</font>"
    return out
}
