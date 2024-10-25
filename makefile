guard-checker: guard_checker.cpp Guard.h Enum.h
	g++ -o guard-checker guard_checker.cpp --std=c++17 -g
install: guard-checker
	cp guard-checker /usr/bin/
