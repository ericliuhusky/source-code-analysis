run: mine apple

mine:
	@echo testing mine...
	@clang++ -c objc.cpp
	@clang -c test.c
	@clang++ test.o objc.o
	@./a.out
	@rm a.out test.o objc.o

apple:
	@echo testing apple...
	@clang -D apple -lobjc test.c
	@./a.out
	@rm a.out
