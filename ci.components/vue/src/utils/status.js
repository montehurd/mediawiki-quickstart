export const getStatusSymbol = ( status ) => {
  switch ( status ) {
    case 'pass': return '✓'
    case 'fail': return 'x'
    case 'none': return '-'
    default: return '?'
  }
}
