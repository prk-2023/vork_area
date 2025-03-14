
import matplotlib.pyplot as plt
import numpy as np

def aufbau_filling(atomic_number):
    orbitals = [
        ('1s', 2), ('2s', 2), ('2p', 6), ('3s', 2), ('3p', 6), ('4s', 2), ('3d', 10),
        ('4p', 6), ('5s', 2), ('4d', 10), ('5p', 6), ('6s', 2), ('4f', 14), ('5d', 10),
        ('6p', 6), ('7s', 2), ('5f', 14), ('6d', 10)
    ]
    
    electron_filling = []
    remaining_electrons = atomic_number
    for orbital, capacity in orbitals:
        electrons_in_orbital = min(remaining_electrons, capacity)
        electron_filling.append((orbital, electrons_in_orbital))
        remaining_electrons -= electrons_in_orbital
        if remaining_electrons <= 0:
            break

    return electron_filling

def plot_orbitals(electron_filling):
    fig, ax = plt.subplots(figsize=(10, 6))  # Correct assignment

    # Check the type of ax to ensure it's an Axes object
    print(f"Type of ax: {type(ax)}")  # It should print <class 'matplotlib.axes._axes.Axes'>

    y_positions = np.arange(len(electron_filling))

    for idx, (orbital, electrons) in enumerate(electron_filling):
        # Plot the electrons in each orbital (2 per electron in the orbital)
        ax.scatter([electrons] * 2, [y_positions[idx]] * 2, s=300, c='blue', zorder=3)

        # Add label for orbital
        ax.text(0, y_positions[idx], f'{orbital} ({electrons} e-)', fontsize=12, ha='right', va='center')

    ax.set_xlim(0, 2)
    ax.set_ylim(-1, len(electron_filling))
    ax.set_xticks([])
    ax.set_yticks(y_positions)
    ax.set_yticklabels([f'{orbital} ({electrons} e-)' for orbital, electrons in electron_filling])
    ax.set_xlabel('Electron Count per Orbital', fontsize=12)
    ax.set_title('Aufbau Principle: Orbital Electron Filling', fontsize=14)

    plt.tight_layout()
    plt.grid(True)
    plt.show()

def main():
    atomic_number = int(input("Enter atomic number: "))

    if atomic_number < 1 or atomic_number > 118:
        print("Invalid atomic number. Please enter a number between 1 and 118.")
        return

    electron_filling = aufbau_filling(atomic_number)
    plot_orbitals(electron_filling)

if __name__ == "__main__":
    main()
