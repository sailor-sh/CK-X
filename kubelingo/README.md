# Custom Facilitator Build Process

This document outlines the process for building a custom `facilitator` Docker image that includes generated questions from the `kubelingo` directory.

This allows you to test your own generated questions without interfering with the standard application setup.

## Files

*   `Dockerfile.facilitator`: A dedicated Dockerfile for building the custom facilitator image. It uses the project root as the build context to access both the `facilitator` application source and the generated questions in `kubelingo/out`.

*   `build_facilitator.sh`: A shell script that orchestrates the custom build. It builds the Docker image using `Dockerfile.facilitator` and tags it as `ckx-facilitator-generated:latest`.

*   `docker-compose.override.yaml`: An override file for Docker Compose. It is stored in this directory to keep all custom build files together.

## Instructions

### 1. Generate Questions

Make sure you have generated your questions and they are located in the `kubelingo/out/facilitator/assets/exams` directory.

### 2. Build the Custom Image

Run the build script from the **root directory** of the project:

```bash
./kubelingo/build_facilitator.sh
```

This will create a new Docker image named `ckx-facilitator-generated:latest`.

### 3. Run the Application with the Custom Image

To use the custom image, you first need to copy the `docker-compose.override.yaml` file from this directory (`kubelingo`) to the project's root directory.

```bash
cp kubelingo/docker-compose.override.yaml .
```

With the `docker-compose.override.yaml` file in the project root, you can start the application as usual:

```bash
docker-compose up -d
```

Docker Compose will automatically merge `docker-compose.yaml` and `docker-compose.override.yaml`, and it will use your custom image for the `facilitator` service.

### 4. Reverting to the Standard Build

To revert to the standard `facilitator` image, simply delete the `docker-compose.override.yaml` file from the project root.

```bash
rm docker-compose.override.yaml
```

With the override file removed, `docker-compose up --build` will build the `facilitator` image from its original `facilitator/Dockerfile`.