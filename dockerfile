##################################Stage 1: Build################################################################

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build

# Set working directory
WORKDIR /src

# Copy solution file and all project files first 
COPY *.sln ./
COPY src/ ./src/

# Restore dependencies 
RUN dotnet restore src/api/server/Server.csproj --verbosity normal

# Build the application
RUN dotnet build src/api/server/Server.csproj -c Release --no-restore --verbosity normal

##################################Stage 2: Publish################################################################

FROM build AS publish

# Publish the application
RUN dotnet publish src/api/server/Server.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    --no-build \
    --verbosity normal \
    /p:PublishProfile="" \
    /p:PublishSingleFile=false \
    /p:PublishReadyToRun=false \
    /p:EnableCompressionInSingleFile=true

####################################Stage 3: Runtime###############################################################

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy published files
COPY --from=publish /app/publish .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port 8080 
EXPOSE 8080
ENTRYPOINT ["dotnet", "FSH.Starter.WebApi.Host.dll"]