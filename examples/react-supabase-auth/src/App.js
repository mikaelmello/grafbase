import { createClient } from '@supabase/supabase-js'
import { Auth } from '@supabase/auth-ui-react'

import { useState, useEffect } from 'react'

const supabase = createClient('', '')

const GetAllMessagesQuery = /* GraphQL */ `
  query GetAllMessages($first: Int!) {
    messageCollection(first: $first) {
      edges {
        node {
          id
          body
        }
      }
    }
  }
`

function App() {
  const [session, setSession] = useState(null)
  const [data, setData] = useState(null)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
    })

    supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
    })
  }, [])

  const fetchData = async () => {
    const response = await fetch('http://localhost:4000/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${session.access_token}`
      },
      body: JSON.stringify({
        query: GetAllMessagesQuery,
        variables: {
          first: 100
        }
      })
    })

    const result = await response.json()
    setData(result)
  }

  return (
    <div className="App">
      <div className="container" style={{ padding: '50px 0 100px 0' }}>
        {!session ? (
          <Auth supabaseClient={supabase} />
        ) : (
          <pre>{JSON.stringify(session, null, 2)}</pre>
        )}
      </div>
      <button onClick={fetchData}>Fetch data</button>
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </div>
  )
}

export default App
