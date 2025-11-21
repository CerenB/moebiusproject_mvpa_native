rm(list = ls()) #clean console
library(ggplot2)
library(plotly)
library(dplyr)
library(Rmisc)


path_results <- paste("/Volumes/extreme/Cerens_files/fMRI",
                      "moebius_topo_analyses/outputs",
                      "derivatives/cosmoMvpa/roi/", sep = "/")

#####
# plot binary class decoding (pairwise)
#####

# first read the pairwise somatotopy
datas <- read.csv(paste0(path_results,
                         paste0("somatotopyPairwiseDecoding_glassierexclusive_",
                                "s2_voxNb250_202511111530.csv")))
datam <- read.csv(paste0(path_results,
                         paste0("mototopyPairwiseDecoding_glassierexclusive_",
                                "s2_voxNb250_202511071625.csv")))
# exclusive masks
# somatotopyPairwiseDecoding_glassierexclusive_s2_voxNb250_202511111530
# mototopyPairwiseDecoding_glassierexclusive_s2_voxNb250_202511071625

# non exclusive masks (overlapping voxels between sensorimotor masks)
# somatotopyPairwiseDecoding_glassier_s2_voxNb250_202511061646
# mototopyPairwiseDecoding_glassier_s2_voxNb250_202511071357

datam$Exp <- "moto"
datas$Exp <- "somato"

print(colnames(datas))
print(colnames(datam))
head(datam)

print(colnames(datam))

# combine data m and data s
data <- rbind(datam, datas)
# check unique decoding conditions
unique(data$decodingConditions)


# Ensure the required columns are present
data <- data %>%
  select(subID, maskArea,  accuracy, maskHemi,
         maskVoxNb, image, decodingConditions, Exp)

# Remove "_binary_exclusive" from maskArea
data$maskArea <- gsub("_binary_exclusive", "", data$maskArea)

head(data)


# make column for group
data <- data %>%
  mutate(group = ifelse(grepl("mbs", subID), "mbs", "ctrl"))

# convert column into factors
data$subID <- as.factor(data$subID)
data$maskArea <- as.factor(data$maskArea)
data$maskHemi <- as.factor(data$maskHemi)
data$image <- as.factor(data$image)
data$decodingConditions <- as.factor(data$decodingConditions)
data$Exp <- as.factor(data$Exp)
data$group <- as.factor(data$group)



# Step 1: Change the first letter of each column name to uppercase
colnames(data) <- gsub("(^)([a-z])", "\\U\\2", colnames(data), perl = TRUE)

# Rename specific columns
colnames(data)[colnames(data) == "MaskArea"] <- "Mask"
colnames(data)[colnames(data) == "MaskHemi"] <- "Hemi"

# Check the updated column names
print(colnames(data))


# Check if all columns are factors
are_factors <- sapply(data, is.factor)

# Print the result
print(are_factors)

# i think datas only has t_maps, check here
unique_images <- unique(data$Image)
print(unique_images)


# check mask column unique values
unique_masks <- unique(data$Mask)

sort(unique(data$DecodingConditions))

sort(unique(data$Exp))


# try to relabel Decodingconditions to be coherent with
# other plots (CoG Distance...)
# Replace 'Forehead' with 'Fore' and 'Tongue' with 'T' in the Pair column
data$DecodingConditions <- gsub("Feet", "Foot", data$DecodingConditions)
data$DecodingConditions <- gsub("_vs_", "-", data$DecodingConditions)
data$DecodingConditions <- gsub("Hand-Foot", "Foot-Hand", data$DecodingConditions)
data$DecodingConditions <- gsub("Tongue-Lips", "Lips-Tongue", data$DecodingConditions)
data$DecodingConditions <- gsub("Tongue-Forehead", "Forehead-Tongue", data$DecodingConditions)
data$DecodingConditions <- gsub("Hand-Forehead", "Forehead-Hand", data$DecodingConditions)
data$DecodingConditions <- gsub("Lips-Forehead", "Forehead-Lips", data$DecodingConditions)

unique(data$DecodingConditions)

unique(data$Mask)


# multiply by 100
data$Accuracy <- data$Accuracy * 100


# for poster SAW 2024
# omit the for loop and plot only 4 (2exp x 2 masks) 
# with averaged values

#1. divide the data
datam <- data %>% filter(Exp == "moto")
datas <- data %>% filter(Exp == "somato")


# 'somato' 'moto'
exp <- "somato"
data_plot <- datas

# sensorimotor_union_binary, area3a_3b_2_1_binary, area3a_3b_binary
# area4_binary,
mask_area <- "area4"

filtered_data <- data_plot %>%
  filter(Mask == mask_area)

# Calculate summary statistics for the filtered data
df <- summarySE(data = filtered_data,
                measurevar = "Accuracy",
                groupvars = c("Mask", "Hemi", "Group", "DecodingConditions"),
                na.rm = TRUE)





# the pairwise conditions reordered
# plot only 4 (2exp x 2 masks) with averaged values
library(showtext)
# Add Avenir font (system font on macOS)
font_add("Avenir", regular = "/System/Library/Fonts/Avenir.ttc")
showtext_auto()

custom_pair_order <- c(
  "Lips-Tongue", "Forehead-Lips", "Forehead-Tongue", "Forehead-Hand",
  "Hand-Lips", "Hand-Tongue", "Foot-Hand", "Foot-Forehead",
  "Foot-Lips", "Foot-Tongue"
)

# Set factor levels according to custom order
df$DecodingConditions <- factor(
                                df$DecodingConditions,
                                levels = custom_pair_order)

# Verify the order is correct
print("Factor levels (this is the x-axis order):")
print(levels(df$DecodingConditions))

# Define position dodge
pos_dodge <- position_dodge(width = 0.8)
# Define your colors
group_colors <- c("ctrl" = "#7b7979", "mbs" = "#63c599")

# Make sure Group is a factor with correct levels
df$Group <- factor(df$Group, levels = c("ctrl", "mbs"))

# define min value of the y axis label
minVal = 65 # 65 for motoExp, sensorimotorunion mask

# VERSION 1: Plot without x-axis labels (for poster/publication)
p1 <- ggplot(df, aes(x = DecodingConditions, y = Accuracy, color = Group)) +
  geom_point(position = pos_dodge, size = 8) +
  geom_errorbar(
    aes(ymin = Accuracy - se, ymax = Accuracy + se, color = Group),
    width = 0.2, position = pos_dodge, size = 1
  ) +
  facet_wrap(~ Hemi) +
  labs(
    x = "Decoding Pairs",
    y = "Accuracy",
    color = "Group"
  ) +
  ylim(minVal, 101) +
  theme_minimal() +
  theme(
    text = element_text(family = "Avenir", color = "black"),
    strip.text = element_text(size = 26, hjust = 0.5),
    axis.text.x = element_blank(),
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

# VERSION 2: Plot with x-axis labels and title (for checking)
plot_title <- paste("Exp", exp, "-", mask_area, "mask")

p2 <- ggplot(df, aes(x = DecodingConditions, y = Accuracy, color = Group)) +
  geom_point(position = pos_dodge, size = 8) +
  geom_errorbar(
    aes(ymin = Accuracy - se, ymax = Accuracy + se, color = Group),
    width = 0.2, position = pos_dodge, size = 1
  ) +
  facet_wrap(~ Hemi) +
  labs(
    title = plot_title,
    x = "Decoding Body Part Pairs",
    y = "Accuracy",
    color = "Group"
  ) +
  ylim(minVal, 101) +
  theme_minimal() +
  theme(
    text = element_text(family = "Avenir", color = "black"),
    plot.title = element_text(size = 30, face = "bold", hjust = 0.5),
    strip.text = element_text(size = 26, hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 20),
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

print(p1)
print(p2)

# Save the plot if desired
filename <- paste(path_results,
                  paste0("Ordered_PairwiseDecodingPlot_Mask_",
                         mask_area, "_", exp, "Exp_averaged.pdf",
                         sep = ""), sep = "")
ggsave(filename, plot = p1, width = 24, height = 5, units = "in", dpi = 300)

filename <- paste(path_results,
                  paste0("Ordered_PairwiseDecodingPlot_Mask_",
                         mask_area, "_", exp, "Exp_averaged_labels.pdf",
                         sep = ""), sep = "")
ggsave(filename, plot = p2, width = 24, height = 7, units = "in", dpi = 300)


##### Stats on decoding accuracy
# ANOVA and permutation ANOVA
# install.packages("broom")
library(broom)


df2 <- summarySE(
  data = filtered_data,
  groupvars = c("Group", "Hemi", "DecodingConditions"),
  measurevar = "Accuracy",
  na.rm = TRUE
)
df2

# ANOVA
anova_model <- aov(Accuracy ~
                     DecodingConditions * Group * Hemi, data = filtered_data)
qqnorm(anova_model$residuals)
qqline(anova_model$residuals)
shapiro.test(anova_model$residuals)

if (!requireNamespace("car", quietly = TRUE)) {
  install.packages("car")
}
library(car)
leveneTest(Accuracy ~ DecodingConditions * Group * Hemi, data = filtered_data)

# Permutation ANOVA
library(permuco)
perm_model <- aovperm(
  Accuracy ~ DecodingConditions * Group * Hemi,
  data = filtered_data, np = 2000
)
results <- summary(perm_model)
print(results)
filename <- paste(
  path_results, "permutationAnovaTable_", exp, "_", mask_area, "_Accuracy.csv", sep = ""
)
write.csv(results, filename)








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














