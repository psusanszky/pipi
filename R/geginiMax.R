# Clean function-only copy of geginiMax3.R; stray prose line removed.
geginiMax <- function(strukt=NULL, rv=NULL) {
	if (is.null(strukt) | is.null(rv)) {
		stop("Please define valid 'strukt' and 'rv' values!") }
	hossz 	<- length(strukt)
	ixx		<- 1:hossz
	ix		<- ixx
	if (rv > sum(strukt)) {
		warning("There are more participants than the entire population! It has been adjusted to sum of participant! Be careful when interpreting the result!", call. = FALSE)	
		rv	<- sum(strukt)
	}
	RV 		<- rv

	ment.str 	<- NULL
	ment.rv 	<- NULL
	ment.ix		<- NULL
	holSTOP.base <- 0

	CS0 <- 1
	CS 	<- 1
	szintlepes <- list()
	szintlepes[[1]]						<- list()
	szintlepes[[1]][["ix.tmp"]]			<- ix 
	szintlepes[[1]][["holSTOP.base"]]	<- 1
	holSTOP								<- 1

	while (CS0 == 1) {
		CS 	<- 1
		szintlepes[[length(szintlepes)]][["ix.tmp"]]		<- ix
		szintlepes[[length(szintlepes)]][["holSTOP.base"]]	<- holSTOP	
#		df.generator(ix)
		cummulalt 	<- cumsum(strukt[ix])
		holSTOP 	<- min(which(cummulalt >= RV))			
		ment.str	<- rbind(ment.str, strukt[ix])
		if (holSTOP > 1) {
			ment.rv <- rbind(ment.rv, c(strukt[ix][1:holSTOP-1], RV-cummulalt[holSTOP-1], rep(0, hossz-holSTOP)))
		} else {
			ment.rv	<- rbind(ment.rv, c(RV, rep(0, hossz-1)))
		}
		ment.ix		<- rbind(ment.ix, ix)
		
		if (holSTOP > szintlepes[[length(szintlepes)]][["holSTOP.base"]] & (holSTOP != hossz)) {  # tehát ha nagyobb szintre lép, és az nem az utolsó szint
			szintlepes[[length(szintlepes)+1]]					<- list()
			szintlepes[[length(szintlepes)]][["holSTOP.base"]]	<- holSTOP
			ix <- c(ix[1:(holSTOP-1)], ix[holSTOP:hossz][c((hossz-holSTOP+1), 1:(hossz-holSTOP))])	# léptetek egyet
			szintlepes[[length(szintlepes)]][["ix.tmp"]]		<- ix
		} else {			# ha a végére ért, vagy ha azonos szinten maradt
			if (holSTOP != hossz & holSTOP != 1) {
				holSTOP	<- szintlepes[[length(szintlepes)]][["holSTOP.base"]]
				ix <- c(ix[1:(holSTOP-1)], ix[holSTOP:hossz][c((hossz-holSTOP+1), 1:(hossz-holSTOP))])
			} else {
				if (holSTOP == hossz) {
					if (length(szintlepes) > 1) { # Ha a végére esik a telítődés, de nem alapból, akkor önmaga marad (következő szintre fog lépni
						ix <- ix
					} else {
						ix <- ix[c(hossz, 1:(hossz-1))]
						holSTOP	<- szintlepes[[length(szintlepes)]][["holSTOP.base"]]
						CS <- 0
					}
				} else {
					ix <- ix[c(hossz, 1:(hossz-1))]
				}
			}
		} 
		if (length(szintlepes)==1 & all(ix == ixx)) { break }					# Ha visszatért a legelejére, akkor álljon meg
		while (CS == 1) {			# addig csinálja míg vagy az alapszintre ér, vagy pedig egy szintet visszalépve még léphet tovább
			if (any(apply(ment.ix, 1, function(x) all(x == ix)))) {	# Ha már volt az adott állapot, akkor lépjen egy szintet vissza és lépjen tovább
				if (length(szintlepes)==1 & all(ix == ixx)) { 
					CS0 <- 0
					break 
				} else {						# visszalépett egyet és léptet egyet
					szintlepes[[length(szintlepes)]]	<- NULL
					ix 		<- szintlepes[[length(szintlepes)]][["ix.tmp"]]
					holSTOP	<- szintlepes[[length(szintlepes)]][["holSTOP.base"]]
					if (holSTOP > 1 ) {  						# tehát ha nem az elsőre ugrott vissza
						ix <- c(ix[1:(holSTOP-1)], ix[holSTOP:hossz][c((hossz-holSTOP+1), 1:(hossz-holSTOP))])	# léptetek egyet
						szintlepes[[length(szintlepes)]][["ix.tmp"]]		<- ix
					} else {
						ix <- ix[c(hossz, 1:(hossz-1))]					# az első szinten is léptetek egyet
						szintlepes[[length(szintlepes)]][["ix.tmp"]]		<- ix
					}
				}
			} else {
				CS <- 0
			}
		}
	}
	xx	<- data.frame(cbind(ment.rv, ment.str))
	geginiMax <- suppressWarnings(max(apply(xx, 1, function(x) gegini(data.frame(p=x[1:(length(x)/2)], k=x[((length(x)/2)+1):length(x)])))))
	class(geginiMax) <- "geginiMax"
	return(geginiMax)
}
