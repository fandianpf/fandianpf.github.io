#!/usr/bin/env ruby

# This ruby script is responsible for rebuilding the YAML for the 
# FandianPF organization's various index.md pages.

require 'pp'
require 'yaml'

$ivyGroup = 'org.fandianpf'

def loadJekyllPage(jekyllPage)
  puts "Loading: [#{jekyllPage}]"
  contents = File.open(jekyllPage, 'r') do | io |
    io.read.split(/\-\-\-/)
  end
  [ YAML::load(contents[1]), contents[2].sub(/^[ \t]*\n/,'') ]
end

def saveCaption(io, indent, caption)
  if caption.empty? then
    io.puts "#{indent}caption:"
  else
    io.puts "#{indent}caption: |"
  end
  caption.each_line do | aLine |
    io.puts "#{indent}  #{aLine}"
  end
end

def saveList(io, listName, list)

  io.puts "#{listName}:" unless list.empty? 

  list.sort{ |a,b| a['title']<=>b['title']}.each do | anItem |
    io.puts "- title: #{anItem['title']}"
    io.puts "  url: #{anItem['url']}"

    caption = anItem['caption']
    saveCaption(io, "  ", caption) if caption

  end
end

def saveJekyllPage(jekyllPage, yaml, contents)
  puts "Saving: [#{jekyllPage}]"

  ivyReleases  = yaml.delete('ivyReleases')  if yaml.has_key?('ivyReleases')
  ctanReleases = yaml.delete('ctanReleases') if yaml.has_key?('ctanReleases')
  papers   = yaml.delete('papers')   if yaml.has_key?('papers')
  projects = yaml.delete('projects') if yaml.has_key?('projects')
  fileList = yaml.delete('fileList') if yaml.has_key?('fileList')

  File.open(jekyllPage, 'w') do | io |
    io.puts "---"
    yaml.keys.sort.each do | aKey |
      if aKey == 'caption' then
        saveCaption(io, '', yaml['caption'])
        next
      end

      io.puts "#{aKey}: #{yaml[aKey]}"
    end
    saveList(io, 'ivyReleases',  ivyReleases)  unless ivyReleases.nil?
    saveList(io, 'ctanReleases', ctanReleases) unless ctanReleases.nil?
    saveList(io, 'papers',   papers)   unless papers.nil?
    saveList(io, 'projects', projects) unless projects.nil?
    saveList(io, 'fileList', fileList) unless fileList.nil?
    io.puts "---"
    io.puts contents
  end
end

def updateRepoIndexPages(aDir) 
  puts "Updating repo index pages in [#{aDir}]"
  indexYaml = Hash.new
  Dir.chdir(aDir) do
    fileList = Array.new
    Dir.entries('.').sort.each do | aFile |
      next if aFile =~ /^\.+$/
      next if aFile =~ /^index.md$/i
      puts "Looking at [#{aFile}]"
      dirYaml = Hash.new
      dirYaml = updateRepoIndexPages(aFile) if File.directory?(aFile);
      listItem = Hash.new
      listItem['title'] = aFile
      listItem['url']   = aFile
      listItem['caption'] = dirYaml['caption'] if dirYaml.has_key?('caption')
      fileList.push(listItem);
    end
    indexYaml, indexContents = loadJekyllPage('index.md') if File.exists?('index.md')
    indexYaml = Hash.new unless indexYaml.is_a?(Hash)
    indexYaml['layout'] = 'indexPage' unless indexYaml.has_key?('layout')
    indexYaml['fileList']  = fileList
    saveJekyllPage('index.md', indexYaml, indexContents)
  end
  indexYaml
end

def gatherPapersInfo(projectName)
  paperDir = "#{$latexRepo}/#{projectName}"
  puts "  looking for paper releases in [#{paperDir}]"
  papers = Array.new
  if File.directory?(paperDir) then
    Dir.chdir(paperDir) do
#      Dir.entries('.').sort.each do | aFile |
#        next unless aFile =~ /\.pdf$/
#        paperInfo = Hash.new
#        paperInfo['title'] = File.basename(aFile,'.zip')
#        paperInfo['url']   = "papers/#{aFile}"
#        papers.push(paperInfo)
#      end
    end
  end
  papers
end

def gatherCtanReleaseInfo(projectName)
  ctanRepo = "#{$ctanRepo}/#{projectName}"
  puts "  looking for ctan releases in [#{ctanRepo}]"
  releases = Array.new
  if File.directory?(ctanRepo) then
    Dir.chdir(ctanRepo) do
#      Dir.entries('.').sort.each do | aFile |
#        next unless aFile =~ /\.zip$/
#        releaseInfo = Hash.new
#        releaseInfo['title'] = File.basename(aFile,'.zip')
#        releaseInfo['url']   = "ctanRepo/#{aFile}"
#        releases.push(releaseInfo)
#      end
    end
  end
  releases
end

def gatherIvyReleaseInfo(projectName)
  ivyRepo = "#{$ivyRepo}/#{projectName}"
  puts "  looking for ivy releases in [#{ivyRepo}]"
  releases = Array.new
  if File.directory?(ivyRepo) then
    Dir.chdir(ivyRepo) do
      Dir.entries('.').sort.each do | aFile |
        next if aFile =~ /^\.+$/
        next if aFile =~ /^index.md$/i
        puts "    found release: [#{aFile}]"
        releaseDetailsPage = aFile+'/index.md'
        releaseDetails = Hash.new
        releaseDetails, releaseContent = loadJekyllPage(releaseDetailsPage) if
          File.exists?(releaseDetailsPage)
        releaseInfo = Hash.new
        releaseInfo['title'] = File.basename(aFile)
        releaseInfo['url']   = "/ivyRepo/#{$ivyGroup}/#{projectName}/#{aFile}"
        releaseInfo['caption'] = releaseDetails['caption'] if
          releaseDetails.has_key?('caption')
        releases.push(releaseInfo)
      end
    end
  end
  releases
end

def updateProjectPage(projectPage)
  puts "Found project page: [#{projectPage}]"
  projectName = File.basename(projectPage,'.md')
  projectYaml, projectContents = loadJekyllPage(projectPage)
  projectYaml = Hash.new unless projectYaml.is_a?(Hash)
  projectYaml['layout'] = 'projectPage' unless projectYaml.has_key?('layout')
  if projectYaml['layout'] == 'projectPage' then
    projectYaml['ivyReleases']  = gatherIvyReleaseInfo(projectName)
    projectYaml['ctanReleases'] = gatherCtanReleaseInfo(projectName)
    projectYaml['papers']       = gatherPapersInfo(projectName)
    saveJekyllPage(projectPage, projectYaml, projectContents)
  end
  projectYaml
end

def gatherProjectInfo
  projects = Array.new
  Dir.entries('.').sort.each do | aFile |
    next if aFile =~ /^\.+$/
    next if aFile == '.git'
    next if aFile == 'css'
    next if aFile =~ /^_/
    next if aFile =~ /^ivyRepo$/
    next if aFile =~ /^ctanRepo$/
    next if aFile =~ /^latexRepo$/

    if File.directory?(aFile) then
      orgYaml = Hash.new
      Dir.chdir(aFile) do
        orgYaml = updateIndexPage('index.md') if File.exists?('index.md')
      end
      projectInfo = Hash.new
      projectInfo['title']   = aFile
      projectInfo['url']     = aFile+'/index.html'
      projectInfo['caption'] = orgYaml['caption'] if 
        orgYaml.has_key?('caption')
      projects.push(projectInfo)
      next
    end

    next unless aFile =~ /\.md$/
    next if aFile =~ /^index\.md$/
    next if aFile =~ /^readme\.md$/i

    projectYaml = updateProjectPage(aFile)

    projectInfo = Hash.new
    projectName = File.basename(aFile, '.md')
    projectInfo['title']   = projectName
    projectInfo['url']     = projectName+'.html'
    projectInfo['caption'] = projectYaml['caption'] if 
      projectYaml.has_key?('caption')
    projects.push(projectInfo)
  end
  projects
end

def updateIndexPage(indexPage)
  puts "Working on index page: [#{Dir.pwd}/#{indexPage}]"
  orgYaml, orgContents = loadJekyllPage(indexPage)
  orgYaml = Hash.new unless orgYaml.is_a?(Hash)
  orgYaml['projects'] = gatherProjectInfo
  orgYaml['layout']   = 'organizationPage'
  saveJekyllPage(indexPage, orgYaml, orgContents)
  orgYaml
end

# Collect the absolute paths to the various repositories we will use
$ivyRepo   = "#{Dir.pwd}/ivyRepo/#{$ivyGroup}"
$ctanRepo  = "#{Dir.pwd}/ctanRepo"
$latexRepo = "#{Dir.pwd}/latexRepo"

updateRepoIndexPages('ivyRepo')

updateIndexPage('index.md')

