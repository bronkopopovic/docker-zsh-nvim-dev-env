FROM debian:stable

# install software
RUN apt update
RUN apt upgrade
RUN apt install -y \
    sudo \
    zsh \
    git \
    curl \
    wget \
    clang \
    gcc \
    python3-pip \
    ninja-build \
    gettext \
    libtool \
    libtool-bin \
    autoconf \
    automake \
    g++ \
    pkg-config \
    unzip \
    cmake

# Neovim 0.5 nightly installation
RUN git clone https://github.com/neovim/neovim.git /neovim
WORKDIR /neovim
RUN mkdir .deps
WORKDIR /neovim/.deps
RUN cmake ../third-party
RUN make
RUN mkdir ../build
WORKDIR /neovim/build
RUN cmake ..
RUN make
RUN make install
WORKDIR /
RUN rm -rf /neovim

# nvm environment variables
RUN mkdir /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 14.15.1
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.37.2/install.sh | bash

# install node and npm
RUN . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# User setup
ARG USERNAME=roman
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/zsh --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
USER $USERNAME

# ZSH, oh-my-zsh & plugins setup
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
COPY ./.zshrc /home/roman/.zshrc

# Neovim Config
RUN sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
RUN mkdir /home/roman/.config
RUN mkdir /home/roman/.config/nvim
COPY ./minimal.vim /home/roman/.config/nvim/init.vim
RUN nvim +PlugInstall +qall

RUN git clone https://github.com/bronkopopovic/dotfiles.git /home/roman/.dotfiles
RUN cd /home/roman/.dotfiles && git checkout macbook
RUN rm -rf /home/roman/.config/nvim
RUN ln -s /home/roman/.dotfiles/.config/nvim /home/roman/.config/nvim

# shell entrypoint
WORKDIR /home/roman
ENTRYPOINT ["zsh"]
