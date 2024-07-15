import { createContact } from '../api/createContact.js';

export default class modalForm {
  formDiv: HTMLDivElement;
  loadingShade: HTMLDivElement;
  title: HTMLDivElement;
  form: HTMLFormElement;
  submitButton: HTMLButtonElement;
  modalFormDiv: HTMLDivElement;

  constructor() {
    this.formDiv = document.createElement("div");
    this.loadingShade = document.createElement("div");
    this.title = document.createElement("div");
    this.form = document.createElement("form");
    this.submitButton = document.createElement("button");
    this.modalFormDiv = <HTMLDivElement> document.getElementById("modal-form");
  }

  setModalVisibility(visibility: boolean) {
    this.modalFormDiv.className = visibility ? "visible-modal": "hidden-modal";
  }


  render(type: modalType, contact?: contact) {
    if (type == "create") {
      const title: string = "Nuevo contacto";
      const formItems: HTMLInputElement[] = [
        // Name field
        this.generateInputTextForm("name", "Nombre"),

        // Number field
        this.generateInputTextForm("number", "Numero", "tel"),

        // Email field
        this.generateInputTextForm("email", "Correo", "email"),
      ];

      this.generateForm(title, formItems);
      this.generateCloseButton();

      if (this.modalFormDiv.innerHTML.trim() == "") {
        this.setModalVisibility(true);
        this.modalFormDiv.appendChild(this.generateCloseButton());
        this.modalFormDiv.appendChild(this.formDiv);
      } else {
        console.error("modalFormDiv was ready");
      }
    }

    if (type == "edit") {
        const title: string = "Editar contacto";
    
        const formItems: HTMLInputElement[] = [
          // Name field
          
          this.generateInputTextForm("name", "Nombre", "text", contact && contact[1]),
  
          // Number field
          this.generateInputTextForm("phone", "Numero", "tel", contact && contact[2]),
  
          // Email field
          this.generateInputTextForm("email", "Correo", "email",  contact && contact[3]),
        ];
  
        this.generateForm(title, formItems);
        this.generateCloseButton();
  
        if (this.modalFormDiv.innerHTML.trim() == "") {
          this.setModalVisibility(true);
          this.modalFormDiv.appendChild(this.generateCloseButton());
          this.modalFormDiv.appendChild(this.formDiv);
        } else {
          console.error("modalFormDiv was ready");
        }
    }
  }

  private generateCloseButton() {
    var button: HTMLButtonElement = document.createElement("button");
    button.className = "close-button";
    button.innerHTML = `<span class="X"></span><span class="Y"></span>`;

    button.addEventListener("click", () => {
      console.log("Close create modal");
      var modalForm: HTMLElement | null = document.getElementById("modal-form");
      if (modalForm == null) throw new Error("modal-form is null");
      console.log("change class");
      modalForm.className = "hidden-modal";
      modalForm.innerHTML = "";
    });
    return button;
  }

  private generateForm(title: string, formItems: HTMLInputElement[]) {
    this.formDiv.className = "card__front";

    this.loadingShade.id = "loading-shade";
    this.loadingShade.className = "loading-shade-create-form hidden";
    this.loadingShade.innerHTML = `<div class="loader">
  <li class="ball"></li>
  <li class="ball"></li>
  <li class="ball"></li>
</div>`;

    this.title.textContent = title;
    this.title.className = "title";

    this.form.className = "card__form";

    this.form.innerHTML = "";

    formItems.forEach((input:HTMLInputElement) => {
        this.form.appendChild(input);
    })


    // Submit button
    this.submitButton.textContent = "Guardar";
    this.submitButton.className = "card__btn";
    this.submitButton.type = "submit";

    this.form.appendChild(this.submitButton);

    async function submitCreateForm(this: HTMLFormElement, ev: SubmitEvent) {
      ev.preventDefault();
      console.log("Submit Create Form");

      // Get loading shade element
      const loading = document.getElementById("loading-shade");
      if (loading == null) throw new Error("Not loading shade loaded.");
      loading.className = "loading-shade-create-form";

      // Gather form data
      const formData = new FormData(ev.target as HTMLFormElement);
      const newContact = {
        name: formData.get('name') as string,
        phone: formData.get('number') as string,
        email: formData.get('email') as string,
      };

      // Call createContact and handle the result
      try {
        const createdContact = await createContact(newContact);
        console.log('Contact created:', createdContact);
        // Handle successful contact creation (e.g., update the UI, clear the form, etc.)
        loading.className = "loading-shade-create-form hidden"; // Hide loading indicator
      } catch (error) {
        console.error('Error creating contact:', error);
        // Handle the error (e.g., display an error message to the user)
        loading.className = "loading-shade-create-form hidden"; // Hide loading indicator
      }

      location.reload();
    }

    // Form submit
    this.form.addEventListener("submit", submitCreateForm);

    this.formDiv.appendChild(this.title);
    this.formDiv.appendChild(this.form);
    this.formDiv.appendChild(this.loadingShade);
  }

  private generateInputTextForm(
    name: string,
    placeholder: string,
    type: string = "text",
    defaultValue: string = ""
  ): HTMLInputElement {
    var inputText: HTMLInputElement = document.createElement("input");
    inputText.className = "card__input";
    inputText.name = name;
    inputText.placeholder = placeholder;
    inputText.type = type;
    inputText.value = defaultValue;
    return inputText;
  }
}
