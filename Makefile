DC = dmd
DFLAGS = -O -release -inline -noboundscheck -wi -m32
LOCAL_RUNNER = java -jar local-runner.jar true false 3 result.txt true false

SRC=$(wildcard *.d) $(wildcard */*.d)

all : MyStrategy

MyStrategy : $(SRC)
	$(DC) $(DFLAGS) $(SRC) -of$@

run : MyStrategy
	$(LOCAL_RUNNER)&
	sleep 2
	./MyStrategy

clean :
	$(RM) MyStrategy *.o compilation.log result.txt
