import React from "react"
import Layout from "@theme/Layout"
import Link from "@docusaurus/Link"

export default function Features() {
  return (
    <Layout title="Features" description="HyperDigits features">
      <main style={{ padding: "3rem 0" }}>
        <div className="container">
          <h1>Features</h1>
          <p>Put your feature list here.</p>

          <p>
            <Link to="/docs/intro">Go to Docs</Link>
          </p>
        </div>
      </main>
    </Layout>
  )
}
