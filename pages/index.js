import React, { useEffect, useRef } from "react"
import Head from "@docusaurus/Head"
import Link from "@docusaurus/Link"
import useDocusaurusContext from "@docusaurus/useDocusaurusContext"
import Layout from "@theme/Layout"
import clsx from "clsx"
import styles from "./index.module.css"

function HomepageHeader() {
    const { siteConfig } = useDocusaurusContext()
    const bannerImage = siteConfig.customFields.bannerImage
    const hasBannerImage = bannerImage ? true : false
    const heroBannerStyle = hasBannerImage ? { backgroundImage: `url("${bannerImage}")` } : undefined

    const titleClassName = clsx("hero__title", {
        [styles.titleOnBannerImage]: hasBannerImage
    })
    const taglineClassName = clsx("hero__subtitle", {
        [styles.taglineOnBannerImage]: hasBannerImage
    })

    return (
        <header className={clsx("hero", styles.heroBanner)} style={heroBannerStyle}>
            <div className={clsx("container", styles.heroContainer)}>
                <div className={styles.badges}>
                    <a
                        href="https://github.com/wiindsom/HyperDigits/actions/workflows/ci.yaml"
                        target="_blank"
                        rel="noopener noreferrer"
                    >
                        <img
                            alt="CI"
                            src="https://img.shields.io/github/actions/workflow/status/wiindsom/HyperDigits/ci.yaml?branch=main&label=CI&logo=github&style=for-the-badge"
                        />
                    </a>

                    <a href="https://wiindsom.github.io/HyperDigits/" target="_blank" rel="noopener noreferrer">
                        <img
                            alt="Docs"
                            src="https://img.shields.io/badge/docs-passing-success?style=for-the-badge"
                        />
                    </a>
                </div>

                <div className={styles.heroImageWrap}>
                    <img
                        src="/HyperDigits/og-image.png"
                        alt="HyperDigits"
                        className={styles.heroImage}
                        draggable={false}
                    />
                </div>

                <h1 className={titleClassName}>{siteConfig.title}</h1>

                <p className={taglineClassName}>
                    {siteConfig.tagline}{" "}
                    <a href="https://github.com/evilbocchi/AlyaNum" target="_blank" rel="noopener noreferrer">
                        AlyaNum❤️
                    </a>
                </p>

                <p className={clsx(taglineClassName, styles.credit)}>
                    🌟Built by{" "}
                    <a href="https://github.com/wiindsom" target="_blank" rel="noopener noreferrer">
                        Arc
                    </a>{" "}
                    +{" "}
                    <a href="https://github.com/evilbocchi" target="_blank" rel="noopener noreferrer">
                        evilbocchi
                    </a>
                    🌟
                </p>

                <div className={styles.buttons}>
                    <Link className="button button--secondary button--lg" to="/docs/intro">
                        Get Started →
                    </Link>
                </div>
            </div>
        </header>
    )
}

export default function Home() {
    const { siteConfig, tagline } = useDocusaurusContext()
    const rootRef = useRef(null)

    useEffect(() => {
        const root = rootRef.current
        if (!root) return

        const applyFooterHeight = () => {
            const footer = document.querySelector("footer.footer")
            const h = footer ? footer.getBoundingClientRect().height : 0
            root.style.setProperty("--homepage-footer-height", `${h}px`)
        }

        applyFooterHeight()

        const footer = document.querySelector("footer.footer")
        const ro = footer ? new ResizeObserver(applyFooterHeight) : null
        if (footer && ro) ro.observe(footer)

        window.addEventListener("resize", applyFooterHeight)

        return () => {
            window.removeEventListener("resize", applyFooterHeight)
            if (ro) ro.disconnect()
        }
    }, [])

    return (
        <div ref={rootRef}>
            <Layout title={siteConfig.title} description={tagline}>
                <Head>
                    <title>HyperDigits</title>
                    <meta property="og:title" content="HyperDigits" />
                    <meta property="og:description" content="A bignum library for Roblox." />
                    <meta property="og:image" content="https://wiindsom.github.io/HyperDigits/og-image.png" />
                    <meta property="og:site_name" content="wiindsom" />
                    <meta name="theme-color" content="#642639ff" />
                    <meta name="twitter:card" content="summary_large_image" />
                </Head>
                <HomepageHeader />
                <div className="container"></div>
            </Layout>
        </div>
    )
}
