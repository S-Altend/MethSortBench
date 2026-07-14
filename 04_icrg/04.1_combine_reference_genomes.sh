
REFERENCE_DIR="/omics/groups/OE0219/internal/altendorfer/epiproper_data/reference_genomes"

### SPECIFY GENOME PATHS
GENOME_HUMAN="GRCh38.p14-genomic"
GENOME_MOUSE="GRCm38-genomic"

GENOME_HUMAN_PATH="$REFERENCE_DIR/$GENOME_HUMAN.fna"
GENOME_MOUSE_PATH="$REFERENCE_DIR/$GENOME_MOUSE.fna"

BISMARK_GENOME_DIR="$REFERENCE_DIR/bismark_${GENOME_HUMAN}_${GENOME_MOUSE}_combined"

############################################################
### BUILD COMBINED GENOME (only once)
############################################################

mkdir -p "$BISMARK_GENOME_DIR"

# # Create edited mouse genome with m.chr prefix
cp "$GENOME_MOUSE_PATH" "${GENOME_MOUSE_PATH%.fna}_edited.fna"
sed -i '/^>/ s/>/>m./' "${GENOME_MOUSE_PATH%.fna}_edited.fna"

# Combine human + edited mouse genome into one FASTA
COMBINED_FASTA="$REFERENCE_DIR/${GENOME_HUMAN}_${GENOME_MOUSE}_combined"
cat "$GENOME_HUMAN_PATH" "${GENOME_MOUSE_PATH%.fna}_edited.fna" > "${COMBINED_FASTA}".fna
