#!/usr/bin/env ruby

# This ruby script is responsible for rebuilding the YAML for the 
# FandianPF organization's various index.md pages.

require 'pp'
require 'yaml'

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

  releases = yaml.delete('releases') if yaml.has_key?('releases')
  papers   = yaml.delete('papers')   if yaml.has_key?('papers')
  projects = yaml.delete('projects') if yaml.has_key?('projects')

  File.open(jekyllPage, 'w') do | io |
    io.puts "---"
    yaml.keys.sort.each do | aKey |
      if aKey == 'caption' then
        saveCaption(io, '', yaml['caption'])
        next
      end

      io.puts "#{aKey}: #{yaml[aKey]}"
    end
    saveList(io, 'releases', releases) unless releases.nil?
    saveList(io, 'papers',   papers)   unless papers.nil?
    saveList(io, 'projects', projects) unless projects.nil?
    io.puts "---"
    io.puts contents
  end
end

def gatherPapersInfo(projectDir)
  papers = Array.new
  paperDir = projectDir+'/papers'
  if File.directory?(paperDir) then
    Dir.chdir(paperDir) do
      Dir.entries('.').sort.each do | aFile |
        next unless aFile =~ /\.pdf$/
        paperInfo = Hash.new
        paperInfo['title'] = File.basename(aFile,'.zip')
        paperInfo['url']   = "papers/#{aFile}"
        papers.push(paperInfo)
      end
    end
  end
  papers
end

def gatherReleaseInfo(projectDir)
  releases = Array.new
  ctanRepo = projectDir+'/ctanRepo'
  if File.directory?(ctanRepo) then
    Dir.chdir(ctanRepo) do
      Dir.entries('.').sort.each do | aFile |
        next unless aFile =~ /\.zip$/
        releaseInfo = Hash.new
        releaseInfo['title'] = File.basename(aFile,'.zip')
        releaseInfo['url']   = "ctanRepo/#{aFile}"
        releases.push(releaseInfo)
      end
    end
  end
  releases
end

def gatherProjectInfo
  projects = Array.new
  Dir.entries('.').sort.each do | aFile |
    next unless File.directory?(aFile)
    next if aFile =~ /^\.+$/
    next if aFile == '.git'
    next if aFile == 'css'
    next if aFile =~ /^_/

    jekyllPageName = aFile+'/index.md'
    projectYaml, projectContents = loadJekyllPage(jekyllPageName)
    projectYaml['releases'] = gatherReleaseInfo(aFile)
    projectYaml['papers']   = gatherPapersInfo(aFile)
    projectYaml['layout']   = 'projectPage'
    saveJekyllPage(jekyllPageName, projectYaml, projectContents)

    projectInfo = Hash.new
    projectInfo['title']   = aFile
    projectInfo['url']     = aFile
    projectInfo['caption'] = projectYaml['caption'] if 
      projectYaml.has_key?('caption')
    projects.push(projectInfo)
  end
  projects
end

orgYaml, orgContents = loadJekyllPage('index.md')
orgYaml['projects'] = gatherProjectInfo
orgYaml['layout']   = 'organizationPage'
saveJekyllPage('index.md', orgYaml, orgContents)
