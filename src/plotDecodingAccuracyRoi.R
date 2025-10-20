rm(list = ls()) #clean console
library(ggplot2)
library(plotly)
library(dplyr)
library(Rmisc)


pathResults <- '//Volumes/extreme/Cerens_files/fMRI/MoebiusProject_backup/MoebiusProject/derivatives/cosmoMvpa/'

########
datam <- read.csv(paste(pathResults, 'mototopyDecoding_hcpex_s2_ratio150_202407192156.csv', sep ='/'))
datas <- read.csv(paste(pathResults, 'somatotopyDecoding_hcpex_s2_ratio150_202408161540.csv', sep ='/'))
# mototopyDecoding_hcpex_s2_ratio150_202407192156
# somatotopyDecoding_hcpex_s2_ratio150_202408161540

datam$Exp <- 'moto'
datas$Exp <- 'somato'

print(colnames(datam))
print(colnames(datas))

datam$decodingCondition<-NULL
data<- rbind(datam, datas)


head(data)



# Ensure the required columns are present
data <- data %>%
  select(subID, maskLabel,  accuracy, maskHemi,
         maskVoxNb, image, decodingConditions, Exp)

# make column for group
data <- data %>%
  mutate(group = ifelse(grepl("mbs", subID), "mbs", "ctrl"))

# convert column into factors
data$subID <- as.factor(data$subID)
data$maskLabel <- as.factor(data$maskLabel)
data$maskHemi <- as.factor(data$maskHemi)
data$image <- as.factor(data$image)
data$decodingConditions <- as.factor(data$decodingConditions)
data$Exp <- as.factor(data$Exp)
data$group <- as.factor(data$group)



# Step 1: Change the first letter of each column name to uppercase
colnames(data) <- gsub("(^)([a-z])", "\\U\\2", colnames(data), perl = TRUE)

# Rename specific columns
colnames(data)[colnames(data) == "MaskLabel"] <- "Mask"
colnames(data)[colnames(data) == "MaskHemi"] <- "Hemi"
colnames(data)[colnames(data) == "Image"] <- "4DImage"

# Check the updated column names
print(colnames(data))


# Check if all columns are factors
are_factors <- sapply(data, is.factor)

# Print the result
print(are_factors)


# Step 2: Filter the data
data <- data %>%
  filter(`4DImage` == 't_maps')



# Step 3: Create a new column with numeric labels for Mask
data <- data %>%
  mutate(MaskLabel = as.numeric(factor(Mask, levels = unique(Mask))))

# Check the updated data
head(data)

# Reorder Mask based on MaskLabel
data <- data %>%
  mutate(Mask = factor(Mask, levels = unique(Mask[order(MaskLabel)])))







#####
# plot multi-class decoding
#####

# Filter for BodyParts5 & OmitTongueBodyParts4
chosenCondition =  "OmitTongueBodyParts4"

data_plot <- data %>%
  filter(DecodingConditions == chosenCondition)

head(data_plot)



# Get the unique values of 'Mask'
unique_masks <- unique(data_plot$Mask)

# Split the masks into two groups
masks_somato <- unique_masks[1:5]  # First 5 masks
masks_moto <- unique_masks[6:11] # Remaining 6 masks

# Filter data for each group
data_somato <- data_plot %>% filter(Mask %in% masks_somato)
data_moto <- data_plot %>% filter(Mask %in% masks_moto)


plot_facet <- function(data, title) {
  
  # Calculate the summary statistics (mean and standard error)
  df <- summarySE(data = data, 
                  measurevar = 'Accuracy', 
                  groupvars = c('Mask', 'Hemi', 'Group', 'Exp'), 
                  na.rm = TRUE)
  
  # Base ggplot with jitter, error bars, and custom colors
  p <- ggplot(df, aes(x = interaction(Group, Exp), y = Accuracy, color = interaction(Group, Exp))) +
    geom_jitter(data = data, 
                aes(x = interaction(Group, Exp), y = Accuracy), 
                width = 0.2, alpha = 0.5, size = 1) +
    geom_point(position = position_dodge(width = 0.5), size = 3) +
    geom_errorbar(aes(ymin = Accuracy - se, ymax = Accuracy + se), 
                  width = 0.2, position = position_dodge(width = 0.5)) +
    facet_grid(Mask ~ Hemi) +
    scale_color_manual(values = c(
      "ctrl.moto" = "#FF6666", "ctrl.somato" = "#FFCCCC",
      "mbs.moto" = "#6666FF", "mbs.somato" = "#CCCCFF"
    )) +
    labs(title = title, x = "Group & Exp", y = "Accuracy") +
    theme_minimal() +
    theme(
      strip.text = element_text(size = 10, face = "bold"),
      strip.background = element_rect(fill = "lightgray", color = "black"),
      panel.border = element_rect(color = "black", fill = NA, size = 0.5),
      panel.spacing = unit(1, "lines"),  # Increase spacing between panels
     # axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid.major = element_line(color = "gray90"),  # Optional: Add grid lines for better readability
      panel.grid.minor = element_blank()
    )
  
  return(p)
}


# Generate the first plot for the first 5 somato masks
plot_somato <- plot_facet(data_somato, paste(chosenCondition,"Decoding in Sensory Cx Masks"))
filenameS <- paste(pathResults, paste(chosenCondition,"_somatoMasks.png",sep = ''), sep = '')

# Generate the second plot for the remaining 5 masks
plot_moto <- plot_facet(data_moto, paste(chosenCondition,"Decoding in Motor Cx Masks"))
filenameM <- paste(pathResults, paste(chosenCondition,"_motoMasks.png",sep = ''), sep = '')

# Display the plots
print(plot_somato)
print(plot_moto)

# save the plots
ggsave(filenameS, plot = plot_somato, width = 10, height = 10, units = "in", dpi = 300)
ggsave(filenameM, plot = plot_moto, width = 10, height = 10, units = "in", dpi = 300)














#####
# plot binary class decoding (pairwise)
#####

# first read the pairwise somatotopy
# datas <- read.csv(paste(pathResults, 'somatotopyDecoding_hcpex_s2_ratio150_202408161540.csv', sep ='/'))
# datam <- read.csv(paste(pathResults, 'mototopyDecoding_hcpex_s2_ratio150_202407192156.csv', sep ='/'))
# 
# datam$Exp <- 'moto'
# datas$Exp <- 'somato'

print(colnames(datas))
print(colnames(datam))
head(datam)


# datam$decodingCondition<- NULL
# print(colnames(datam))

# combine data m and data s
data<- rbind(datam, datas)

# omit multiclass decoding from datam
data <- data %>%
  filter(!(decodingConditions %in% c("BodyParts5", "OmitTongueBodyParts4")))


unique_conditions <- unique(data$decodingConditions)
unique_conditions



# Ensure the required columns are present
data <- data %>%
  select(subID, maskLabel,  accuracy, maskHemi,
         maskVoxNb, image, decodingConditions, Exp)

head(data)


# make column for group
data <- data %>%
  mutate(group = ifelse(grepl("mbs", subID), "mbs", "ctrl"))

# convert column into factors
data$subID <- as.factor(data$subID)
data$maskLabel <- as.factor(data$maskLabel)
data$maskHemi <- as.factor(data$maskHemi)
data$image <- as.factor(data$image)
data$decodingConditions <- as.factor(data$decodingConditions)
data$Exp <- as.factor(data$Exp)
data$group <- as.factor(data$group)



# Step 1: Change the first letter of each column name to uppercase
colnames(data) <- gsub("(^)([a-z])", "\\U\\2", colnames(data), perl = TRUE)

# Rename specific columns
colnames(data)[colnames(data) == "MaskLabel"] <- "Mask"
colnames(data)[colnames(data) == "MaskHemi"] <- "Hemi"

# Check the updated column names
print(colnames(data))


# Check if all columns are factors
are_factors <- sapply(data, is.factor)

# Print the result
print(are_factors)

# i think datas only has t_maps, check here
unique_images <- unique(data$Image)
# unique_images <- unique(datas$image)


# Step 2: Filter the data with tmaps only
data <- data %>%
  filter(`Image` == 't_maps')

# check mask column unique values
unique_masks <- unique(data$Mask)

sort(unique(data$DecodingConditions))

sort(unique(data$Exp))


# try to relabel Decodingconditions to be coherent with other plots (CoG Distance...)
# Replace 'Forehead' with 'Fore' and 'Tongue' with 'T' in the Pair column
#data$DecodingConditions <- gsub("Forehead", "Fore", data$DecodingConditions)
#data$DecodingConditions <- gsub("Tongue", "T", data$DecodingConditions)
data$DecodingConditions <- gsub("Feet", "Foot", data$DecodingConditions)
data$DecodingConditions <- gsub("_vs_", "-", data$DecodingConditions)
data$DecodingConditions <- gsub("Hand-Foot", "Foot-Hand", data$DecodingConditions)
data$DecodingConditions <- gsub("Tongue-Lips", "Lips-Tongue", data$DecodingConditions)
data$DecodingConditions <- gsub("Tongue-Forehead", "Forehead-Tongue", data$DecodingConditions)
data$DecodingConditions <- gsub("Hand-Forehead", "Forehead-Hand", data$DecodingConditions)
data$DecodingConditions <- gsub("Lips-Forehead", "Forehead-Lips", data$DecodingConditions)

unique(data$DecodingConditions)

unique(data$Mask)

# filter to debug the plot issue
# just take one mask and plot to zoom in
filtered_data <- data %>%
  filter(Mask == 1)

sort(unique(filtered_data$Exp))

df <- summarySE(data = filtered_data, 
                measurevar = 'Accuracy', 
                groupvars = c('Hemi', 'Group', 'Exp', 'DecodingConditions'), 
                na.rm = TRUE)
df

print(str(filtered_data))
print(str(df))


pos_dodge <- position_dodge(width = 0.8)

p <- ggplot(data = df, aes(x = DecodingConditions, y = Accuracy, color = interaction(Group, Exp))) +
  geom_jitter(data = filtered_data,
              aes(x = DecodingConditions, y = Accuracy, color = interaction(Group, Exp)),
              position = position_jitterdodge(jitter.width = 0.15, dodge.width = 0.8), # height = 0.1
              size = 1, alpha = 0.5) +
  geom_point(position = pos_dodge, size = 3) +
  geom_errorbar(aes(ymin = Accuracy - se, ymax = Accuracy + se),
                width = 0.2, position = pos_dodge) +
  facet_wrap(Mask ~ Hemi) +
  labs(title = "Accuracy by Decoding Conditions", x = "Decoding Conditions", y = "Accuracy") +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 10, hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    legend.position = "top",
    legend.title = element_blank(),
    legend.text = element_text(size = 8),
    panel.spacing = unit(1, "lines")
  ) +
  scale_color_manual(values = c(
    "ctrl.moto" = "#FF6666", "ctrl.somato" = "#FFCCCC",
    "mbs.moto" = "#6666FF", "mbs.somato" = "#CCCCFF"
  ))

print(p)

# this was an example of Mask1 - so no need to ssve the plot 




# 23/08/2024 - STOPPED HERE
# START FROM HERE NEXT TIME TI GO THROUGH IT

# plot the pairwise decoding  in a for loop for Masks

# multiply by 100
data$Accuracy = data$Accuracy*100

# Loop through each level of the Mask variable
for (mask_level in unique(data$Mask)) {
  
  # Filter data for the current mask level
  filtered_data <- data %>%
    filter(Mask == mask_level)
  
  # Calculate summary statistics for the filtered data
  df <- summarySE(data = filtered_data, 
                  measurevar = 'Accuracy', 
                  groupvars = c('Hemi', 'Group', 'Exp', 'DecodingConditions'), 
                  na.rm = TRUE)
  
  # Define position dodge
  pos_dodge <- position_dodge(width = 0.8)
  
  # Create the plot
  p <- ggplot(data = df, aes(x = DecodingConditions, y = Accuracy, color = interaction(Group, Exp))) +
    geom_jitter(data = filtered_data,
                aes(x = DecodingConditions, y = Accuracy, color = interaction(Group, Exp)),
                position = position_jitterdodge(jitter.width = 0.15, dodge.width = 0.8),
                size = 1, alpha = 0.5) +
    geom_point(position = pos_dodge, size = 3) +
    geom_errorbar(aes(ymin = Accuracy - se, ymax = Accuracy + se),
                  width = 0.2, position = pos_dodge) +
    facet_wrap(Mask ~ Hemi) +
    #ylim(0, 40)
    labs(title = paste("Accuracy by Pairwise Decoding for Mask Label", mask_level), 
         x = "Pairwise Decoding Conditions", 
         y = "Accuracy") +
    theme_minimal() +
    theme(
      strip.text = element_text(size = 10, hjust = 0.5),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      legend.position = "top",
      legend.title = element_blank(),
      legend.text = element_text(size = 8),
      panel.spacing = unit(1, "lines")
    ) +
    scale_color_manual(values = c(
      "ctrl.moto" = "#FF6666", "ctrl.somato" = "#FFCCCC",
      "mbs.moto" = "#6666FF", "mbs.somato" = "#CCCCFF"
    ))
  
  # Print the plot for the current mask level
  print(p)
  
  # Save the plot if desired
  filename <- paste(pathResults, paste0("PairwiseDecodingPlot_Mask_", mask_level, ".png",sep = ''), sep = '')
#  ggsave(filename, plot = p, width = 10, height = 8, units = "in", dpi = 300)
}




# plot only the averaged obe - to have a clear plot without indiv. points
# Loop through each level of the Mask variable
for (mask_level in unique(data$Mask)) {
  
  # Filter data for the current mask level
  filtered_data <- data %>%
    filter(Mask == mask_level)
  
  # Calculate summary statistics for the filtered data
  df <- summarySE(data = filtered_data, 
                  measurevar = 'Accuracy', 
                  groupvars = c('Mask', 'Hemi', 'Group', 'Exp', 'DecodingConditions'), 
                  na.rm = TRUE)
  
  # Define position dodge
  pos_dodge <- position_dodge(width = 0.8)
  
  # Create the plot with only summary points and error bars
  p <- ggplot(data = df, aes(x = DecodingConditions, y = Accuracy, color = interaction(Group, Exp))) +
    geom_point(position = pos_dodge, size = 8) +
    geom_errorbar(aes(ymin = Accuracy - se, ymax = Accuracy + se),
                  width = 0.2, position = pos_dodge) +
    facet_wrap(~ Hemi) +  # Faceting only by Hemi now
    labs(x = "Decoding Conditions", 
         y = "Accuracy") +
    ylim(70, 100) +
    theme_minimal() +
    theme(
      strip.text = element_text(size = 22, hjust = 0.5),  # Facet text size
      axis.text.x = element_text(angle = 45, hjust = 1, size = 22),  # X-axis tick label size
      axis.text.y = element_text(size = 22),  # Y-axis tick label size (this is new)
      axis.title.y = element_text(size = 24),  # Y-axis title size
      axis.title.x = element_text(size = 24),  # X-axis title size
      panel.grid.major.x = element_blank(),  # Remove major grid lines on x-axis
      panel.grid.minor.x = element_blank(),  # Remove minor grid lines on x-axis
      legend.position = "top",  # Legend on top
      legend.title = element_blank(),  # Remove legend title
      legend.text = element_text(size = 20),  # Legend text size
      panel.spacing = unit(1, "lines")  # Adjust panel spacing
    ) +
    scale_color_manual(values = c(
      "ctrl.moto" = "#FF6666", "ctrl.somato" = "#FFCCCC",
      "mbs.moto" = "#6666FF", "mbs.somato" = "#CCCCFF"
    ))
  
  # Print the plot for the current mask level
  print(p)
  
  # Save the plot if desired
  filename <- paste(pathResults, paste0("PairwiseDecodingPlot_Mask_", mask_level, "_averaged.pdf",sep = ''), sep = '')
  ggsave(filename, plot = p, width = 24, height = 6, units = "in", dpi = 300)
}






# for poster SAW 2024
# omit the for loop and plot only 4 (2exp x 2 masks) 
# with averaged values

#1. divide the data
datam <- data %>% filter(Exp == "moto")
datas <- data %>% filter(Exp == "somato")

data_plot <- datam
exp <- 'moto'
mask_level <- '4'

filtered_data <- data_plot %>%
  filter(Mask == mask_level)

# Calculate summary statistics for the filtered data
df <- summarySE(data = filtered_data, 
                measurevar = 'Accuracy', 
                groupvars = c('Mask', 'Hemi', 'Group', 'DecodingConditions'), 
                na.rm = TRUE)

# Define position dodge
pos_dodge <- position_dodge(width = 0.8)

# Create the plot with only summary points and error bars
p <- ggplot(data = df, aes(x = DecodingConditions, y = Accuracy, color = Group)) +
  geom_point(position = pos_dodge, size = 12) +
  geom_errorbar(aes(ymin = Accuracy - se, ymax = Accuracy + se),
                width = 0.2, position = pos_dodge) +
  facet_wrap(~ Hemi) +  # Faceting only by Hemi now
  labs(x = "Decoding Conditions", 
       y = "Accuracy", color = "Group") +
  ylim(70, 100) +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 26, hjust = 0.5),  # Facet text size
    axis.text.x = element_text(angle = 45, hjust = 1, size = 26),  # X-axis tick label size
    axis.text.y = element_text(size = 26),  # Y-axis tick label size (this is new)
    axis.title.y = element_text(size = 28),  # Y-axis title size
    axis.title.x = element_text(size = 28),  # X-axis title size
    panel.grid.major.x = element_blank(),  # Remove major grid lines on x-axis
    panel.grid.minor.x = element_blank(),  # Remove minor grid lines on x-axis
    legend.position = "top",  # Legend on top
    legend.text = element_text(size = 24),  # Legend text size
    legend.title = element_text(size = 24),  # Legend text size
    panel.spacing = unit(6, "lines")  # Adjust panel spacing
  ) +
  scale_color_manual(
    name = 'Group',
    values = c("ctrl" = "#FF6666","mbs" = "#6666FF")
    )

# Print the plot for the current mask level
print(p)

# Save the plot if desired
filename <- paste(pathResults, paste0("PairwiseDecodingPlot_Mask_", mask_level,'_', exp, "Exp_averaged.pdf",sep = ''), sep = '')
ggsave(filename, plot = p, width = 24, height = 8, units = "in", dpi = 300)





# for poster SAW 2025 - reordering the pairwise conditions 
# omit the for loop and plot only 4 (2exp x 2 masks) 
# with averaged values

#1. divide the data
datam <- data %>% filter(Exp == "moto")
datas <- data %>% filter(Exp == "somato")

data_plot <- datas
exp <- 'somato'
mask_level <- '123ab'

filtered_data <- data_plot %>%
  filter(Mask == mask_level)

# Calculate summary statistics for the filtered data
df <- summarySE(data = filtered_data, 
                measurevar = 'Accuracy', 
                groupvars = c('Mask', 'Hemi', 'Group', 'DecodingConditions'), 
                na.rm = TRUE)

custom_pair_order <- c(
  "Lips-Tongue", "Forehead-Lips", "Forehead-Tongue", "Forehead-Hand",
  "Hand-Lips", "Hand-Tongue", "Foot-Hand", "Foot-Forehead",
  "Foot-Lips", "Foot-Tongue"
)
df$pair_order_dist <- match(df$DecodingConditions, custom_pair_order)
df$DecodingConditions <- factor(df$DecodingConditions, levels = custom_pair_order)

# Define position dodge
pos_dodge <- position_dodge(width = 0.8)
# Define your colors
group_colors <- c("ctrl" = "#7b7979", "mbs" = "#63c599")

# Make sure Group is a factor with correct levels
df$Group <- factor(df$Group, levels = c("ctrl", "mbs"))

# Dot plot with error bars
p <- ggplot(df, aes(x = DecodingConditions, y = Accuracy, color = Group)) +
  geom_point(position = pos_dodge, size = 8) +
  geom_errorbar(
    aes(ymin = Accuracy - se, ymax = Accuracy + se, color = Group),
    width = 0.2, position = pos_dodge, size = 1
  ) +
  facet_wrap(~ Hemi) +
  labs(
    x = "Decoding Conditions",
    y = "Accuracy (%)",
    color = "Group"
  ) +
  ylim(70, 100) +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 26, hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 26),
    axis.text.y = element_text(size = 26),
    axis.title.y = element_text(size = 28, face = "bold"),
    axis.title.x = element_text(size = 28, face = "bold"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    legend.position = "top",
    legend.text = element_text(size = 24),
    legend.title = element_text(size = 24),
    panel.spacing = unit(6, "lines")
  ) +
  scale_color_manual(values = group_colors)

print(p)

# Save the plot if desired
filename <- paste(pathResults, paste0("Ordered_PairwiseDecodingPlot_Mask_", mask_level,'_', exp, "Exp_averaged.pdf",sep = ''), sep = '')
ggsave(filename, plot = p, width = 24, height = 8, units = "in", dpi = 300)












# #####
# chosenCondition =  "Pairwise"
# # Get the unique values of 'Mask'
# unique_masks <- unique(data$Mask)
# 
# # Split the masks into two groups
# masks_somato <- unique_masks[1:5]  # First 5 masks
# masks_moto <- unique_masks[6:11] # Remaining 6 masks
# 
# # Filter data for each group
# data_somato <- data %>% filter(Mask %in% masks_somato)
# data_moto <- data%>% filter(Mask %in% masks_moto)
# 
# 
# plot_facet <- function(data, title) {
#   
#   # Calculate the summary statistics (mean and standard error)
#   df <- summarySE(data = data, 
#                   measurevar = 'Accuracy', 
#                   groupvars = c('Mask', 'Hemi', 'Group', 'Exp'), 
#                   na.rm = TRUE)
#   
#   # Base ggplot with jitter, error bars, and custom colors
#   p <- ggplot(df, aes(x = interaction(Group, Exp), y = Accuracy, color = interaction(Group, Exp))) +
#     geom_jitter(data = data, 
#                 aes(x = interaction(Group, Exp), y = Accuracy), 
#                 width = 0.2, alpha = 0.5, size = 1) +
#     geom_point(position = position_dodge(width = 0.5), size = 3) +
#     geom_errorbar(aes(ymin = Accuracy - se, ymax = Accuracy + se), 
#                   width = 0.2, position = position_dodge(width = 0.5)) +
#     facet_grid(Mask ~ Hemi) +
#     scale_color_manual(values = c(
#       "ctrl.moto" = "#FF6666", "ctrl.somato" = "#FFCCCC",
#       "mbs.moto" = "#6666FF", "mbs.somato" = "#CCCCFF"
#     )) +
#     labs(title = title, x = "Group & Exp", y = "Accuracy") +
#     theme_minimal() +
#     theme(
#       strip.text = element_text(size = 10, face = "bold"),
#       strip.background = element_rect(fill = "lightgray", color = "black"),
#       panel.border = element_rect(color = "black", fill = NA, size = 0.5),
#       panel.spacing = unit(1, "lines"),  # Increase spacing between panels
#       # axis.text.x = element_text(angle = 45, hjust = 1),
#       panel.grid.major = element_line(color = "gray90"),  # Optional: Add grid lines for better readability
#       panel.grid.minor = element_blank()
#     )
#   
#   return(p)
# }
# 
# 
# # Generate the first plot for the first 5 somato masks
# plot_somato <- plot_facet(data_somato, paste(chosenCondition,"Decoding in Sensory Cx Masks"))
# filename <- paste(pathResults, paste(chosenCondition,"_somatoMasks.png",sep = ''), sep = '')
# ggsave(filename, plot = plot_somato, width = 10, height = 10, units = "in", dpi = 300)
# 
# # Generate the second plot for the remaining 5 masks
# plot_moto <- plot_facet(data_moto, paste(chosenCondition,"Decoding in Motor Cx Masks"))
# filename <- paste(pathResults, paste(chosenCondition,"_motoMasks.png",sep = ''), sep = '')
# ggsave(filename, plot = plot_moto, width = 10, height = 10, units = "in", dpi = 300)
# 
# # Display the plots
# print(plot_somato)
# print(plot_moto)














