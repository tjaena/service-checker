# Not file targets.
.PHONY: help install install-scripts

### Macros ###
SRCS_SCRIPTS	= $(filter-out %cron_mail, $(wildcard usr/local/sbin/*))

# Just set PREFIX in envionment, like
# $ PREFIX=/tmp/test make
DEST_SCRIPTS	= $(PREFIX)/usr/local/sbin


### Targets ###
# target: all - Default target.
all: install

# target: help - Display all targets.
help:
	@egrep "#\starget:" [Mm]akefile  | sed 's/\s-\s/\t\t\t/' | cut -d " " -f3- | sort -d

# target: install - Install all files
install: install-scripts


# target: install-scripts - Install executables.
install-scripts:
	install -d $(DEST_SCRIPTS)
	install -m 0744 $(SRCS_SCRIPTS) $(DEST_SCRIPTS)