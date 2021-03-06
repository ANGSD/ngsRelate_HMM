library(Relate)

calculate.a<-function(k0,k1,k2,phi=0.013){
    if(k2==0){
       ma<-1-log(k1)/log(2)
       mb=0
    }else{
       xa<-(k1+2*k2+sqrt((k1+2*k2)^2-4*k2))/2
       xb<-k2/xa
       ma<-1-log(xa)/log(2)
       mb<-1-log(xb)/log(2)
    }
    m<-ma+mb
    a<--m*log(1-phi)
    #cat("m=",m," ma=",ma," mb=",mb," a=",a," k0=",k0," k1=",k1," k2=",k2,"\n")
     return(a)
}

getLikes<-function(geno,dep,e=0.01,norm=FALSE){
  d<-dep
  n<-length(geno)
  dep<-rpois(n,d)
  nA<-rbinom(n,dep,c(e,0.5,1-e)[geno+1])
  res<-rbind(dbinom(nA,dep,e),dbinom(nA,dep,0.5),dbinom(nA,dep,1-e))
  if(norm)
    res<-t(t(res)/colSums(res))
  res
}

getPerfectLikes<-function(genovec){
  res <- matrix(0,ncol=length(genovec),nrow=3)
  res[1,which(genovec==0)]=1
  res[2,which(genovec==1)]=1
  res[3,which(genovec==2)]=1
  res
}

getEpsilonLikes_old<-function(obsgenovec,eps=0.01){
  res <- matrix(NA,ncol=3,nrow=length(obsgenovec))

  res[obsgenovec==0,1]=(1-eps)^2
  res[obsgenovec==0,2]=2*(1-eps)*eps
  res[obsgenovec==0,3]=eps^2
  
  res[obsgenovec==1,1]=(1-eps)*eps
  res[obsgenovec==1,2]=eps^2+(1-eps)^2
  res[obsgenovec==1,3]=eps*(1-eps)

  res[obsgenovec==2,1]=eps^2
  res[obsgenovec==2,2]=2*(1-eps)*eps
  res[obsgenovec==2,3]=(1-eps)^2
                
  res
}

getEpsilonLikes_new<-function(obsgenovec,eps=0.01){
  res <- matrix(NA,ncol=3,nrow=length(obsgenovec))

  res[obsgenovec==0,1]=(1-eps)^2
  res[obsgenovec==0,2]=(1-eps)*eps
  res[obsgenovec==0,3]=eps^2
  
  res[obsgenovec==1,1]=2*(1-eps)*eps
  res[obsgenovec==1,2]=eps^2+(1-eps)^2
  res[obsgenovec==1,3]=2*eps*(1-eps)

  res[obsgenovec==2,1]=eps^2
  res[obsgenovec==2,2]=(1-eps)*eps
  res[obsgenovec==2,3]=(1-eps)^2
                
  res
}


doMLgenoCalling<-function(likes){
  apply(likes,2,which.max)
}


simData<-function(nind,nsnp,nchr,k0,k1,a=NULL,min=0.05,max=0.95,nsnpprcm=5){
  # find pars
  k2=1-k0-k1
  if(is.null(a))
    a=calculate.a(k0,k1,k2,phi=0.013)

  # sim freqs
  freq<-runif(nsnp,min=min,max=max) #the population allele frequency of the SNPs (assumed to be uniform for SNP chip data)

  # sim genos for nind inds (to make nsnp genos in each each of nchr chromosomes for each ind))
  data<-matrix(rbinom(nind*nsnp*nchr,2,rep(freq,nind*nchr)),ncol=nsnp*nchr,byrow=T)+1 
  
  # sim genos for related inds (also nchr chr with nsnp snps in each)
  r<-replicate(nchr,sim_chr_new(nsnp,freq=freq, min=0.5, max=0.95, k=c(k0,k1,k2), a=a, number_per_cm=nsnpprcm ),simplify = F)
  states<-t(unlist(sapply(r,function(x) x$state)))
  pos<-as.vector(unlist(sapply(r,function(x) x$pos)))
  chr=rep(1:nchr,each=nsnp)
  geno<-unlist(sapply(r,function(x) x$geno))

  # combine data (two first inds related)
  combigeno<-rbind(rbind(as.vector(geno[1:nsnp,]),as.vector(geno[1:nsnp+nsnp,]))+1,data)

  # return all sim data
  list(geno=combigeno,pos=pos,chr=chr,truepaths=states,truefreq=rep(freq,nchr))
}
