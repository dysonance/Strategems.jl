# CHECK THIS OUT
# it could be possible to take a Julia expression
# (like calling an EMA function w/ kw args)
# and figure out what the parameter variables are
# this could make it SUPER easy to adapt the parameter set
# or throw different input variables (like mktdata) on the fly
calc = :(ema(x, n=20))
dump(calc)  # show the syntax call tree
calc.args  # show the arguments of the epxression that we care about

# we can then decompose the call into its constituent parts
# AND SWAP VARIABLES IN AND OUT
s1 = "$(calc.args[1])($(calc.args[2]), $(calc.args[3]))"
ex = parse(s1)  # turn the string into an Expr object
x_out = eval(ex)  # and call it at will

# we can even throw other data at it
y = diff(log(x))
s2 = "$(calc.args[1])(y, $(calc.args[3]))"
ex = parse(s2)
y_out = eval(ex)

# or different function arguments
s3 = "$(calc.args[1])(x, n=40)"
ex = parse(s3)
z_out = eval(ex)

