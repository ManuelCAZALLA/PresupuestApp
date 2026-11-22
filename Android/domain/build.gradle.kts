import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlin.jvm)
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.fromTarget("17")
    }
}

tasks.withType<JavaCompile>().configureEach {
    sourceCompatibility = "17"
    targetCompatibility = "17"
}

sourceSets {
    test {
        resources.srcDir("../../Packages/QuoteCore/Tests/QuoteCoreTests/Fixtures")
        resources.include("quote_calculator_vectors.tsv")
    }
}

dependencies {
    testImplementation(kotlin("test-junit"))
    testImplementation(libs.junit)
}

tasks.test {
    useJUnit()
}
