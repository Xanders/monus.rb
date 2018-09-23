build:
	gem build monus.gemspec | grep File: | cut -d " " -f4 | xargs gem push