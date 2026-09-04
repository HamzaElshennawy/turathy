allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Removed evaluationDependsOn(":app") — forced full graph evaluation on every subproject,
// slowing builds and encouraging extra Gradle daemon spawns during parallel agent tasks.
// Flutter plugin loader resolves plugin deps without this hook (Gradle 8.14 / AGP 8.11).

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
