##' @title Download clinical data in GDC
##' @description Download clinical data in GDC 
##'   either by providing the manifest file or specifying the project id and data type
##' @param manifest menifest file that is downloaded from the GDC cart. If provided, files whose UUIDs 
##'   are in the manifest file will be downloaded via gdc-client, 
##'   otherwise, \code{project id} argument should be provided to download data automatically. 
##'   Default is \code{NULL}
##' @param project.id project id in GDC
##' @param directory the folder to save downloaded files. Default is \code{'Clinical'}
##' @param write.manifest logical, whether to write out the manifest file
##' @return downloaded files in the specified directory
##' @export
##' @author Ruidong Li and Han Qu
##' @examples
##' ####### Download Clinical data by manifest file #######
##' manifest <- 'Clinical.manifest.txt'
##' \dontrun{gdcClinicalDownload(manifest  = manifest,
##'                     directory = 'Clinical')}
##'                    
##' ####### Download Clinical data by project id #######
##' project <- 'TCGA-PRAD'
##' \dontrun{gdcClinicalDownload(project.id     = project, 
##'                     write.manifest = TRUE,
##'                     directory      = 'Clinical')}
gdcClinicalDownload <- function(manifest=NULL, project.id, directory='Clinical', 
                                write.manifest=FALSE) {

    data.type = 'Clinical'
    
    if (! is.null(manifest)) {
        manifestDownloadFun(manifest=manifest,directory=directory)
        
    } else {
        
        url <- gdcGetURL(project.id=project.id, data.type=data.type)
        manifest <- read.table(paste(url, '&return_type=manifest', sep=''), 
                               header=TRUE, stringsAsFactors=FALSE)
        
        systime <- gsub(' ', 'T', Sys.time())
        systime <- gsub(':', '-', systime)
        
        manifile <- paste(project.id, data.type, 'gdc_manifest', systime, 'txt', sep='.')
        write.table(manifest, file=manifile, row.names=FALSE, sep='\t', quote=FALSE)
        
        manifestDownloadFun(manifest=manifile,directory=directory)
        
        if (write.manifest == FALSE) {
            invisible(file.remove(manifile))
        }
    }
}



##' @title Merge clinical data
##' @description Merge clinical data in \code{.xml} files that are downloaded from GDC to a dataframe
##' @param path path to downloaded files for merging
##' @param key.info logical, whether to return the key clinical information only. If \code{TRUE}, 
##'   only clinical information such as age, stage, grade, overall survial, etc. will be returned 
##' @importFrom XML xmlParse
##' @importFrom XML xmlApply
##' @importFrom XML getNodeSet
##' @importFrom XML xmlValue
##' @importFrom XML xmlName
##' @return A dataframe of clinical data with rows are patients and columns are clinical traits
##' @export
##' @author Ruidong Li and Han Qu
##' @examples 
##' ####### Merge clinical data #######
##' path <- 'Clinical/'
##' \dontrun{clinicalDa <- gdcClinicalMerge(path=path, key.info=TRUE)}
gdcClinicalMerge <- function(path, key.info=TRUE) {
  
    options(stringsAsFactors = FALSE)
    
    #if (endsWith(path, '/')) {
    #  path = substr(path, 1, nchar(path)-1)
    #}
    
    cat ('############### Merging Clinical data ###############\n')
    
    folders <- file.path(path, dir(path), fsep = .Platform$file.sep)
    
    folders <- folders[dir.exists(folders)]
    
    filenames <- file.path(folders, unlist(lapply(folders, function(v) 
        getXMLFile(v))), fsep = .Platform$file.sep)
    
    df <- lapply(filenames, function(fl) parseXMLFun(fl))
    traits <- unique(names(unlist(df)))
    xmlMatrix <- do.call('cbind', lapply(df, function(v) v[traits]))
    
    rownames(xmlMatrix) <- traits
    colnames(xmlMatrix) <- xmlMatrix['bcr_patient_barcode',]
    xmlMatrix[xmlMatrix==""]<- "NA"
    xmlMatrix<- data.frame(xmlMatrix)
    if (key.info== TRUE){
        
        line1<- xmlMatrix[c("age_at_initial_pathologic_diagnosis","ethnicity", "gender", "race",
                            "clinical_stage", "clinical_T","clinical_N", "clinical_M", "gleason_grading",
                            "gleason_score", "primary_pattern","secondary_pattern","tertiary_pattern",
                            "psa","psa_value","days_to_psa"),]
        
        
        ### days_to_death
        
        num3<- grep("^days_to_death", rownames(xmlMatrix))
        t3<- xmlMatrix[num3,]
        t3[is.na(t3)]<-"0"
        
        line2<- data.frame(t(apply(t3, 2, max)))
        line2[line2=="0"]<- "NA"
        rownames(line2)<- "days_to_death"
        
        
        ### days_to_last_followup
        
        num4<- grep("^days_to_last_followup", rownames(xmlMatrix))
        t4<- xmlMatrix[num4,]
        t4[is.na(t4)]<-"0"
        
        line3<- data.frame(t(apply(t4, 2, max)))
        line3[line3=="0"]<- "NA"
        rownames(line3)<- "days_to_last_followup"
        
        
        ### vital_status
        num11<- grep("^vital_status", rownames(xmlMatrix))
        t11<- xmlMatrix[num11,]
        t11[is.na(t11)]<-"0"
        
        line5<- data.frame(t(apply(t11, 2, max)))
        line5[line5=="0"]<- "NA"
        rownames(line5)<- "vital_status"
        
        ### age_at_initial_pathologic_diagnosis
        
        line6<- xmlMatrix[c("initial_pathologic_diagnosis_method", "lymphnodes_examined",
                            "number_of_lymphnodes_examined","number_of_lymphnodes_positive_by_he",
                            "pathologic_categories", "pathologic_stage","pathologic_T", "pathologic_M","pathologic_N",
                            "new_tumor_event"),]
        
        ### days_to_new_tumor_event_after_initial_treatment
        
        num5<- grep("^days_to_new_tumor_event_after_initial_treatment", rownames(xmlMatrix))
        t5<- xmlMatrix[num5,]
        t5[is.na(t5)]<-"0"
        
        line7<- data.frame(t(apply(t4, 2, min)))
        line7[line7=="0"]<- "NA"
        rownames(line7)<- "days_to_new_tumor_event_after_initial_treatment"
        
        
        ### new_neoplasm_event_type
        
        num6<- grep("^new_neoplasm_event_type", rownames(xmlMatrix))
        t6<- xmlMatrix[num6,]
        # t6[is.na(t6)]<-"0"
        line8<- NULL
        
        for (i in 1:ncol(t6)) {
            t6.1<- t6[which(t6[,i] != "NA"),i]
            t6.1<- paste(t6.1,collapse=",")
            line8<- append(line8,t6.1)
        }
        line8<-data.frame(t(line8))
        line8[line8==""]<- "NA"
        rownames(line8)<-"new_neoplasm_event_type"
        colnames(line8) <- colnames(t6)
        
        
        ### new_tumor_event_after_initial_treatment
        
        num7<- grep("^new_tumor_event_after_initial_treatment", rownames(xmlMatrix))
        t7<- xmlMatrix[num7,]
        t7[is.na(t7)]<-"0"
        
        t7.1<- data.frame(t((colSums(t7=="YES"))))
        rownames(t7.1)<- "new_tumor_event_after_initial_treatment_yes"
        
        t7.2<- data.frame(t((colSums(t7=="NO"))))
        rownames(t7.2)<- "new_tumor_event_after_initial_treatment_no"
        
        line9<- rbind(t7.1,t7.2)
        
        
        #### additional_pharmaceutical_therapy
        num<- grep("^additional_pharmaceutical_therapy", rownames(xmlMatrix))
        t1<- xmlMatrix[num,]
        t1[is.na(t1)]<-"0"
        
        t1.1<- data.frame(t((colSums(t1=="YES"))))
        rownames(t1.1)<- "additional_pharmaceutical_therapy_yes"
        
        t1.2<- data.frame(t((colSums(t1=="NO"))))
        rownames(t1.2)<- "additional_pharmaceutical_therapy_no"
        
        line10<- rbind(t1.1,t1.2)
        
        
        ### additional_radiation_therapy
        
        num2<- grep("^additional_radiation_therapy", rownames(xmlMatrix))
        t2<- xmlMatrix[num2,]
        t2[is.na(t2)]<-"0"
        
        t2.1<- data.frame(t((colSums(t2=="YES"))))
        rownames(t2.1)<- "additional_radiation_therapy_yes"
        
        t2.2<- data.frame(t((colSums(t2=="NO"))))
        rownames(t2.2)<- "additional_radiation_therapy_no"
        
        line11<- rbind(t2.1,t2.2)
        
        
        
        ########## rbind #########
        
        cleantable<- rbind(line1, line2, line3, line5, line6, line7, line8, line9, line10, line11)
        #names(cleantable)<- names(line3)
        #colnames(line7)<- names(line3)
        #cleantable<- rbind(cleantable, line3, line7)
        cleantable <- data.frame(t(cleantable), stringsAsFactors = FALSE)
        
        rownames(cleantable) <- gsub('.', '-', rownames(cleantable), fixed=TRUE)
        
        filter <- grep('^NA',colnames(cleantable))
        
        if (length(filter) > 0) {
            cleantable <- cleantable[,-filter]
        }
        
        return(cleantable)
        
    } else{
        return(xmlMatrix)
    }
}


####
parseXMLFun <- function(fl) {
    doc<-xmlParse(file = fl)
    test1<- xmlApply(getNodeSet(doc, "//*"), xmlValue)
    test2<- xmlApply(getNodeSet(doc, "//*"), xmlName)
    names(test1) <- make.names(unlist(test2), unique = TRUE)
    test1 <- unlist(test1)[-c(1:2)]
    return (test1)
}



####
getXMLFile <- function(folder) {
    files <- dir(folder)
    xmlFile <- files[endsWith(files, '.xml')]
    return (xmlFile)
}
