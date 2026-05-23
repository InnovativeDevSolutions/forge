/**
 * @format
 * @class Dialpad
 * @extends Component
 * @description A phone dialpad component providing a touch-tone keypad interface for making calls. Manages phone number input, formatting, call state, and integration with contacts.
 */

class Dialpad extends Component {
  static fieldCommanderPhoneNumber = '0160000000';

  static assetPath(...parts) {
    return PhoneMedia.base64Path('images', ...parts);
  }

  /**
   * @constructor
   * @param {Object} props - Component properties
   */
  constructor(props = {}) {
    super(props);

    this.state = {
      phoneNumber: '', // Current phone number in the dialpad
      isCallActive: false, // Whether a call is currently in progress
      callDuration: 0, // Duration of active call in seconds
    };

    // Bind event handlers
    this.handleNumberClick = this.handleNumberClick.bind(this);
    this.handleCall = this.handleCall.bind(this);
    this.handleEndCall = this.handleEndCall.bind(this);
    this.handleDelete = this.handleDelete.bind(this);
    this.handleOpenContacts = this.handleOpenContacts.bind(this);
    this.handleGlobalStateChange = this.handleGlobalStateChange.bind(this);

    this.callTimer = null;

    // Subscribe to global state changes
    globalState.subscribe(this.handleGlobalStateChange);
  }

  // -------------------------------------------------------------------------
  // Lifecycle Methods
  // -------------------------------------------------------------------------

  /**
   * @method componentDidMount
   * @description Initializes component after mounting, handling any existing phone number in global state
   */
  componentDidMount() {
    const state = globalState.getState();
    if (state.phoneNumber) {
      this.setState(
        {
          phoneNumber: this.cleanPhoneNumber(state.phoneNumber),
        },
        () => {
          globalState.setState({ phoneNumber: '' });
        }
      );
    }
  }

  /**
   * @method componentWillUnmount
   * @description Cleanup resources and subscriptions when component unmounts
   */
  componentWillUnmount() {
    if (this.callTimer) {
      clearInterval(this.callTimer);
    }
    globalState.unsubscribe(this.handleGlobalStateChange);
  }

  // -------------------------------------------------------------------------
  // Phone Number Utilities
  // -------------------------------------------------------------------------

  /**
   * @method cleanPhoneNumber
   * @description Removes all non-digit characters from a phone number
   * @param {string} number - The phone number to clean
   * @returns {string} The cleaned phone number containing only digits
   */
  cleanPhoneNumber(number) {
    if (!number) return '';
    return number.replace(/\D/g, '');
  }

  /**
   * @method formatPhoneNumber
   * @description Formats a phone number into a readable format
   * @param {string} number - The phone number to format
   * @returns {string} Formatted phone number as (XXX) XXX-XXXX
   */
  formatPhoneNumber(number) {
    if (!number || number.length === 0) return '';

    const cleaned = number.replace(/[^\d]/g, '');

    if (cleaned.length <= 3) {
      return cleaned;
    } else if (cleaned.length <= 6) {
      return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3)}`;
    } else if (cleaned.length <= 10) {
      return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6)}`;
    } else {
      return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6, 10)}`;
    }
  }

  /**
   * @method formatTime
   * @description Formats seconds into MM:SS format
   * @param {number} seconds - Number of seconds to format
   * @returns {string} Time formatted as MM:SS
   */
  formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  // -------------------------------------------------------------------------
  // Event Handlers
  // -------------------------------------------------------------------------

  /**
   * @method handleGlobalStateChange
   * @description Handles changes in the global state, specifically phone number updates
   * @param {Object} newState - The new global state
   */
  handleGlobalStateChange(newState) {
    if (newState.phoneNumber) {
      const cleaned = this.cleanPhoneNumber(newState.phoneNumber);
      if (cleaned && cleaned !== this.state.phoneNumber) {
        this.setState(
          {
            phoneNumber: cleaned,
          },
          () => {
            globalState.setState({ phoneNumber: '' });
          }
        );
      }
    }
  }

  /**
   * @method handleNumberClick
   * @description Handles digit button clicks on the dialpad
   * @param {string} number - The digit that was clicked
   */
  handleNumberClick(number) {
    if (!this.state.isCallActive) {
      this.setState({
        phoneNumber: this.state.phoneNumber + number,
      });
    }
  }

  /**
   * @method handleDelete
   * @description Handles the delete button click, removing the last digit
   */
  handleDelete() {
    if (!this.state.isCallActive) {
      this.setState({
        phoneNumber: this.state.phoneNumber.slice(0, -1),
      });
    }
  }

  /**
   * @method handleCall
   * @description Initiates a phone call and starts the call timer
   */
  handleCall() {
    if (
      this.state.phoneNumber &&
      !this.state.isCallActive &&
      this.cleanPhoneNumber(this.state.phoneNumber) !== Dialpad.fieldCommanderPhoneNumber
    ) {
      this.setState({
        isCallActive: true,
        callDuration: 0,
      });

      this.callTimer = setInterval(() => {
        // Update state directly to avoid re-render during call
        this.state.callDuration = this.state.callDuration + 1;
        
        // Update only the call duration display element
        const durationElement = document.querySelector('.call-duration');
        if (durationElement) {
          durationElement.textContent = this.formatTime(this.state.callDuration);
        }
      }, 1000);
    }
  }

  /**
   * @method handleEndCall
   * @description Ends the current call and resets the dialpad state
   */
  handleEndCall() {
    if (this.callTimer) {
      clearInterval(this.callTimer);
      this.callTimer = null;
    }

    this.setState({
      isCallActive: false,
      callDuration: 0,
      phoneNumber: '',
    });
  }

  /**
   * @method handleOpenContacts
   * @description Navigates to the contacts view
   */
  handleOpenContacts() {
    globalState.setState({
      currentApp: 'contacts',
      previousApp: 'phone',
    });
  }

  // -------------------------------------------------------------------------
  // Render Methods
  // -------------------------------------------------------------------------

  /**
   * @method render
   * @description Renders the phone dialpad interface
   * @returns {Object} Virtual DOM representation of the component
   */
  render() {
    const { phoneNumber, isCallActive, callDuration } = this.state;
    const isPhoneNumberEmpty = phoneNumber.length === 0;

    const dialpadNumbers = [
      ['1', ''],
      ['2', 'ABC'],
      ['3', 'DEF'],
      ['4', 'GHI'],
      ['5', 'JKL'],
      ['6', 'MNO'],
      ['7', 'PQRS'],
      ['8', 'TUV'],
      ['9', 'WXYZ'],
      ['*', ''],
      ['0', '+'],
      ['#', ''],
    ];

    if (isCallActive) {
      return this.createElement(
        'div',
        {
          className: 'phone-dialpad call-active',
          role: 'region',
          'aria-label': 'Active call interface',
        },
        this.createElement(
          'div',
          {
            className: 'call-info',
            role: 'status',
            'aria-live': 'polite',
          },
          this.createElement('div', { className: 'call-status' }, 'Calling...'),
          this.createElement('div', { className: 'call-number' }, this.formatPhoneNumber(phoneNumber)),
          this.createElement('div', { className: 'call-duration' }, this.formatTime(callDuration))
        ),
        this.createElement(
          'div',
          { className: 'call-actions' },
          this.createElement(
            'button',
            {
              className: 'end-call-btn',
              onClick: this.handleEndCall,
              'aria-label': 'End call',
            },
            (() => {
              const imgElement = this.createElement('img', { 
                alt: 'End call',
                style: { display: 'none' }
              });
              
              PhoneMedia.loadImage(Dialpad.assetPath('light', 'HangUp.png')).then(imageContent => {
                imgElement.src = imageContent;
                imgElement.style.display = 'block';
              }).catch(error => {
                console.error('Failed to load hang up icon:', error);
              });
              
              return imgElement;
            })()
          )
        )
      );
    }

    const callButtonProps = {
      className: 'action-btn call-btn',
      onClick: this.handleCall,
      'aria-label': 'Make call',
    };

    if (isPhoneNumberEmpty || this.cleanPhoneNumber(phoneNumber) === Dialpad.fieldCommanderPhoneNumber) {
      callButtonProps.disabled = true;
    }

    return this.createElement(
      'div',
      {
        className: 'phone-dialpad',
        role: 'region',
        'aria-label': 'Phone dialer',
      },
      this.createElement(
        'div',
        {
          className: 'phone-display',
          role: 'textbox',
          'aria-label': 'Phone number display',
        },
        this.createElement('div', { className: 'phone-number' }, this.formatPhoneNumber(phoneNumber) || 'Enter a number')
      ),
      this.createElement(
        'div',
        {
          className: 'dialpad',
          role: 'grid',
          'aria-label': 'Dial pad',
        },
        ...dialpadNumbers.map(([number, letters]) =>
          this.createElement(
            'button',
            {
              className: 'dialpad-btn',
              onClick: () => this.handleNumberClick(number),
              'aria-label': `Dial ${number}${letters ? ` (${letters})` : ''}`,
            },
            this.createElement('span', { className: 'number' }, number),
            letters && this.createElement('span', { className: 'letters' }, letters)
          )
        )
      ),
      this.createElement(
        'div',
        {
          className: 'phone-actions',
          role: 'toolbar',
          'aria-label': 'Phone actions',
        },
        this.createElement(
          'button',
          {
            className: 'action-btn delete-btn',
            onClick: this.handleDelete,
            'aria-label': 'Delete last digit',
          },
          this.createElement('img', {
            src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="grey" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 4H8l-7 8 7 8h13a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2z"/><line x1="18" y1="9" x2="12" y2="15"/><line x1="12" y1="9" x2="18" y2="15"/></svg>',
            alt: 'Delete',
            style: 'width:28px;height:28px;padding:0;margin:4px 4px 0 0;display:block;pointer-events:none;'
          })
        ),
        this.createElement('button', callButtonProps, 
          (() => {
            const imgElement = this.createElement('img', { 
              alt: 'Make call',
              style: { display: 'none' }
            });
            
            PhoneMedia.loadImage(Dialpad.assetPath('light', 'Call.png')).then(imageContent => {
              imgElement.src = imageContent;
              imgElement.style.display = 'block';
            }).catch(error => {
              console.error('Failed to load call icon:', error);
            });
            
            return imgElement;
          })()
        ),
        this.createElement(
          'button',
          {
            className: 'action-btn contact-btn',
            onClick: this.handleOpenContacts,
            'aria-label': 'Open contacts',
          },
          (() => {
            const imgElement = this.createElement('img', { 
              alt: 'Open contacts',
              style: { display: 'none' }
            });
            
            PhoneMedia.loadImage(Dialpad.assetPath('light', 'Contact.png')).then(imageContent => {
              imgElement.src = imageContent;
              imgElement.style.display = 'block';
            }).catch(error => {
              console.error('Failed to load contact icon:', error);
            });
            
            return imgElement;
          })()
        )
      )
    );
  }
}
