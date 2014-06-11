# Building the FandianPF organization GitHubPages

The _build subdirectory contains the ruby scripts required to rebuild 
the FandianPF organization GitHubPages.

This scripts walk all of the subdirectories (other than latexRepo, 
ctanRepo, and ivyRepo) looking for "project" *.md files which describe 
releated "releases".

For each project *.md file, the name of the project as well as the 
contents of the project's *.md yaml's caption field is stored in the 
projects array of the main organizational index.md yaml.

Also for each project *.md file, the list of all released artifacts are 
added to the project's yaml.
