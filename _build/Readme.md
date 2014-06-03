# Building the FandianPF organization GitHubPages

The _build subdirectory contains the ruby scripts required to rebuild 
the FandianPF organization GitHubPages.

This scripts walk all of the subdirectories looking for "releases" 
subsubdirectories which mark a subdirectory as a project subdirectory.

For each project subdirectory, the name of the project as well as the 
contents of the project subdirectory's index.md yaml's caption field is 
stored in the projects array of the main organizational index.md yaml.

Also for each project, the list of all released artifacts are added to 
the project's index.md yaml.
